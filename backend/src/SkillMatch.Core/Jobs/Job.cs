using SkillMatch.Core.Skills;

namespace SkillMatch.Core.Jobs;

/// <summary>
/// Une offre d'emploi, de stage ou de PFE, venue d'une source (voir <see cref="IJobSource"/>).
///
/// Comme <c>User</c> : les setters sont privés, et une offre ne se crée que par
/// <see cref="FromPosting"/> ou ne change que par <see cref="UpdateFrom"/>.
/// Les deux passent par les mêmes contrôles : aucune offre invalide (lien
/// dangereux, compétence en double…) n'arrive jusqu'à la base.
/// </summary>
public sealed class Job
{
    // Limites partagées avec la configuration EF Core (taille des colonnes).
    public const int MaxTitleLength = 200;
    public const int MaxCompanyLength = 200;
    public const int MaxCityLength = 100;
    public const int MaxUrlLength = 2048;
    public const int MaxSourceLength = 50;
    public const int MaxExternalIdLength = 200;

    /// <summary>Au-delà, la liste ne serait plus lisible sur une carte d'offre.</summary>
    public const int MaxSkillsPerJob = 30;

    // Champ privé : seule l'offre ajoute ou retire ses compétences. EF Core le
    // remplit directement (il reconnaît le nom « _skills »).
    private readonly List<JobSkill> _skills = [];

    public Guid Id { get; private set; }

    public string Title { get; private set; } = string.Empty;

    public string Company { get; private set; } = string.Empty;

    public JobType Type { get; private set; }

    public string City { get; private set; } = string.Empty;

    /// <summary>Lien vers l'annonce d'origine (http ou https seulement), ou null.</summary>
    public string? Url { get; private set; }

    /// <summary>Nom de la source (« exemple »…), voir <see cref="IJobSource.Name"/>.</summary>
    public string Source { get; private set; } = string.Empty;

    /// <summary>Identifiant de l'offre chez sa source.</summary>
    public string ExternalId { get; private set; } = string.Empty;

    /// <summary>Vrai pour une offre fictive : l'application affiche alors la mention « exemple ».</summary>
    public bool IsSample { get; private set; }

    /// <summary>Date de publication, en UTC (Npgsql refuse un décalage horaire non nul).</summary>
    public DateTimeOffset PublishedAt { get; private set; }

    /// <summary>Date du dernier import, en UTC.</summary>
    public DateTimeOffset ImportedAt { get; private set; }

    public IReadOnlyList<JobSkill> Skills => _skills;

    // Constructeur vide réservé à EF Core.
    private Job()
    {
    }

    /// <summary>Crée une offre à partir de ce que fournit une source. Lève ArgumentException si elle est invalide.</summary>
    public static Job FromPosting(string source, bool isSample, JobPosting posting)
    {
        var cleanSource = Required(source, MaxSourceLength, nameof(source));
        ArgumentNullException.ThrowIfNull(posting);

        var job = new Job
        {
            // Guid v7, comme pour User : les nouvelles lignes s'ajoutent en fin d'index.
            Id = Guid.CreateVersion7(),
            Source = cleanSource,
            ExternalId = Required(posting.ExternalId, MaxExternalIdLength, nameof(posting.ExternalId)),
            IsSample = isSample,
        };
        job.UpdateFrom(posting);
        return job;
    }

    /// <summary>
    /// Met à jour l'offre lors d'un nouvel import. La source et l'identifiant
    /// externe ne changent jamais : ils servent justement à la retrouver.
    /// Tout est contrôlé AVANT de modifier quoi que ce soit : en cas d'erreur,
    /// l'offre reste telle qu'elle était.
    /// </summary>
    public void UpdateFrom(JobPosting posting)
    {
        ArgumentNullException.ThrowIfNull(posting);

        // ExternalId est toujours rempli ici : FromPosting le pose avant d'appeler UpdateFrom.
        if (Clean(posting.ExternalId) != ExternalId)
        {
            throw new ArgumentException("L'identifiant externe d'une offre ne change pas.", nameof(posting));
        }

        var title = Required(posting.Title, MaxTitleLength, nameof(posting.Title));
        var company = Required(posting.Company, MaxCompanyLength, nameof(posting.Company));
        var city = Required(posting.City, MaxCityLength, nameof(posting.City));
        var url = ValidUrl(posting.Url);
        if (!Enum.IsDefined(posting.Type))
        {
            throw new ArgumentException("Type d'offre inconnu.", nameof(posting));
        }

        var wanted = ValidSkills(posting);

        Title = title;
        Company = company;
        City = city;
        Url = url;
        Type = posting.Type;
        PublishedAt = posting.PublishedAt.ToUniversalTime();
        ImportedAt = DateTimeOffset.UtcNow;
        SyncSkills(wanted);
    }

    /// <summary>
    /// Met la liste à jour sans tout recréer : on retire les compétences
    /// disparues, on change l'importance de celles qui restent, on ajoute les
    /// nouvelles. Recréer une ligne de même clé dans la même sauvegarde
    /// pourrait gêner EF Core ; ici, chaque ligne garde sa clé.
    /// </summary>
    private void SyncSkills(List<(string Name, SkillImportance Importance)> wanted)
    {
        var byName = wanted.ToDictionary(s => s.Name, s => s.Importance, StringComparer.Ordinal);

        _skills.RemoveAll(s => !byName.ContainsKey(s.Name));
        foreach (var skill in _skills)
        {
            skill.Importance = byName[skill.Name];
        }

        var kept = _skills.Select(s => s.Name).ToHashSet(StringComparer.Ordinal);
        foreach (var (name, importance) in wanted)
        {
            if (!kept.Contains(name))
            {
                _skills.Add(new JobSkill(name, importance));
            }
        }
    }

    /// <summary>
    /// Compétences nettoyées, dans l'ordre de l'offre (requises d'abord).
    /// Refuse une liste vide, un nom trop long et un doublon, y compris une
    /// même compétence à la fois requise et souhaitée, ou écrite deux fois de
    /// façons différentes (« JS » et « JavaScript »).
    /// </summary>
    private static List<(string Name, SkillImportance Importance)> ValidSkills(JobPosting posting)
    {
        ArgumentNullException.ThrowIfNull(posting.RequiredSkills);
        ArgumentNullException.ThrowIfNull(posting.PreferredSkills);

        var result = new List<(string, SkillImportance)>();
        var keys = new HashSet<string>(StringComparer.Ordinal);

        void Add(string raw, SkillImportance importance)
        {
            var name = Required(raw, JobSkill.MaxNameLength, "skill");
            var key = SkillKey.For(name);
            if (key.Length == 0)
            {
                throw new ArgumentException($"Compétence sans aucun mot : « {name} ».", nameof(posting));
            }

            if (!keys.Add(key))
            {
                throw new ArgumentException($"Compétence en double dans l'offre : « {name} ».", nameof(posting));
            }

            result.Add((name, importance));
        }

        foreach (var skill in posting.RequiredSkills)
        {
            Add(skill, SkillImportance.Required);
        }

        foreach (var skill in posting.PreferredSkills)
        {
            Add(skill, SkillImportance.Preferred);
        }

        if (result.Count == 0)
        {
            throw new ArgumentException("Une offre doit citer au moins une compétence.", nameof(posting));
        }

        if (result.Count > MaxSkillsPerJob)
        {
            throw new ArgumentException($"Une offre cite au plus {MaxSkillsPerJob} compétences.", nameof(posting));
        }

        return result;
    }

    /// <summary>
    /// Lien facultatif. Seuls http et https sont acceptés : un lien
    /// « javascript: » ou « file: » ouvert par l'application serait dangereux.
    /// </summary>
    private static string? ValidUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            return null;
        }

        var trimmed = url.Trim();
        if (trimmed.Length > MaxUrlLength
            || !Uri.TryCreate(trimmed, UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
        {
            throw new ArgumentException("Le lien d'une offre doit être une adresse http ou https.", nameof(url));
        }

        return trimmed;
    }

    /// <summary>Texte obligatoire : nettoyé, non vide, et pas plus long que <paramref name="maxLength"/>.</summary>
    private static string Required(string? value, int maxLength, string name)
    {
        var cleaned = Clean(value);
        if (cleaned.Length == 0)
        {
            throw new ArgumentException($"Le champ « {name} » est vide.", name);
        }

        if (cleaned.Length > maxLength)
        {
            throw new ArgumentException($"Le champ « {name} » dépasse {maxLength} caractères.", name);
        }

        return cleaned;
    }

    /// <summary>
    /// Espaces retirés autour, et plusieurs espaces de suite réduits à un seul.
    /// Publique pour que l'import cherche une offre sous la forme exacte où
    /// elle a été enregistrée (une seule règle, à un seul endroit).
    /// </summary>
    public static string CleanText(string? value) => Clean(value);

    private static string Clean(string? value) =>
        value is null ? string.Empty : string.Join(' ', value.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
}

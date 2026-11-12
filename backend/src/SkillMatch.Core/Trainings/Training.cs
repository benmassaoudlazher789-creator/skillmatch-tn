// Alias : la propriété SkillKey de cette classe porte le même nom que la
// classe SkillKey du dictionnaire. Sans alias, « SkillKey.For » désignerait
// la propriété (une chaîne) et ne compilerait pas.
using SkillKeys = SkillMatch.Core.Skills.SkillKey;

namespace SkillMatch.Core.Trainings;

/// <summary>
/// Une formation suggérée pour apprendre une compétence, venue d'une source
/// (voir <see cref="ITrainingSource"/>).
///
/// Même construction que <c>Job</c> : setters privés, création par
/// <see cref="FromPosting"/>, mise à jour par <see cref="UpdateFrom"/>, et les
/// deux passent par les mêmes contrôles. Aucune formation invalide (lien
/// dangereux, durée absurde…) n'arrive jusqu'à la base.
/// </summary>
public sealed class Training
{
    // Limites partagées avec la configuration EF Core (taille des colonnes).
    public const int MaxTitleLength = 200;

    /// <summary>40 caractères, comme une compétence d'offre ou saisie dans l'application.</summary>
    public const int MaxSkillLength = 40;

    /// <summary>
    /// Plus large que la compétence : la clé peut être le nom d'une entrée du
    /// dictionnaire, plus long que la variante écrite (« k8s » → « kubernetes »).
    /// </summary>
    public const int MaxSkillKeyLength = 80;

    public const int MaxUrlLength = 2048;
    public const int MaxSourceLength = 50;
    public const int MaxExternalIdLength = 200;

    /// <summary>Durée indicative : au moins 1 heure.</summary>
    public const int MinHours = 1;

    /// <summary>Au-delà, ce n'est plus une formation à suggérer mais un cursus entier.</summary>
    public const int MaxHours = 500;

    public Guid Id { get; private set; }

    /// <summary>Compétence telle que la source l'écrit (« Power BI »), affichée par l'application.</summary>
    public string Skill { get; private set; } = string.Empty;

    /// <summary>
    /// Clé de comparaison de la compétence (voir <see cref="SkillKeys"/>),
    /// calculée une seule fois à l'import. La recherche devient une simple
    /// égalité SQL sur une colonne indexée, avec exactement la même
    /// normalisation que le dictionnaire : « docker » trouve « Docker ».
    /// </summary>
    public string SkillKey { get; private set; } = string.Empty;

    public string Title { get; private set; } = string.Empty;

    public TrainingLevel Level { get; private set; }

    /// <summary>Durée indicative, en heures.</summary>
    public int Hours { get; private set; }

    public TrainingType Type { get; private set; }

    /// <summary>Lien vers la formation (http ou https seulement), ou null.</summary>
    public string? Url { get; private set; }

    /// <summary>Nom de la source (« exemple »…), voir <see cref="ITrainingSource.Name"/>.</summary>
    public string Source { get; private set; } = string.Empty;

    /// <summary>Identifiant de la formation chez sa source.</summary>
    public string ExternalId { get; private set; } = string.Empty;

    /// <summary>Vrai pour une formation fictive : l'application affiche alors la mention « exemple ».</summary>
    public bool IsSample { get; private set; }

    /// <summary>Date du dernier import, en UTC.</summary>
    public DateTimeOffset ImportedAt { get; private set; }

    // Constructeur vide réservé à EF Core.
    private Training()
    {
    }

    /// <summary>Crée une formation à partir de ce que fournit une source. Lève ArgumentException si elle est invalide.</summary>
    public static Training FromPosting(string source, bool isSample, TrainingPosting posting)
    {
        var cleanSource = Required(source, MaxSourceLength, nameof(source));
        ArgumentNullException.ThrowIfNull(posting);

        var training = new Training
        {
            // Guid v7, comme pour User et Job : les nouvelles lignes s'ajoutent en fin d'index.
            Id = Guid.CreateVersion7(),
            Source = cleanSource,
            ExternalId = Required(posting.ExternalId, MaxExternalIdLength, nameof(posting.ExternalId)),
            IsSample = isSample,
        };
        training.UpdateFrom(posting);
        return training;
    }

    /// <summary>
    /// Met à jour la formation lors d'un nouvel import. La source et
    /// l'identifiant externe ne changent jamais : ils servent à la retrouver.
    /// Tout est contrôlé AVANT de modifier quoi que ce soit : en cas
    /// d'erreur, la formation reste telle qu'elle était.
    /// </summary>
    public void UpdateFrom(TrainingPosting posting)
    {
        ArgumentNullException.ThrowIfNull(posting);

        if (Clean(posting.ExternalId) != ExternalId)
        {
            throw new ArgumentException("L'identifiant externe d'une formation ne change pas.", nameof(posting));
        }

        var skill = Required(posting.Skill, MaxSkillLength, nameof(posting.Skill));
        var key = SkillKeys.For(skill);
        if (key.Length == 0)
        {
            throw new ArgumentException($"Compétence sans aucun mot : « {skill} ».", nameof(posting));
        }

        if (key.Length > MaxSkillKeyLength)
        {
            throw new ArgumentException("La clé de la compétence est trop longue.", nameof(posting));
        }

        var title = Required(posting.Title, MaxTitleLength, nameof(posting.Title));
        var url = ValidUrl(posting.Url);

        if (posting.Hours is < MinHours or > MaxHours)
        {
            throw new ArgumentException(
                $"La durée d'une formation va de {MinHours} à {MaxHours} heures.", nameof(posting));
        }

        if (!Enum.IsDefined(posting.Level))
        {
            throw new ArgumentException("Niveau de formation inconnu.", nameof(posting));
        }

        if (!Enum.IsDefined(posting.Type))
        {
            throw new ArgumentException("Type de formation inconnu.", nameof(posting));
        }

        Skill = skill;
        SkillKey = key;
        Title = title;
        Level = posting.Level;
        Hours = posting.Hours;
        Type = posting.Type;
        Url = url;
        ImportedAt = DateTimeOffset.UtcNow;
    }

    /// <summary>
    /// Ordre d'affichage, le même que dans l'application mobile
    /// (TrainingFinder) : niveau (Débutant d'abord), puis durée (la plus
    /// courte d'abord), puis titre, puis Id. Un ordre complet garantit le
    /// même affichage à chaque appel.
    ///
    /// Fait en C# et non en SQL : le niveau est enregistré en texte, et
    /// l'ordre alphabétique de « avance », « debutant »… n'est pas l'ordre
    /// des niveaux.
    /// </summary>
    public static IReadOnlyList<Training> InDisplayOrder(IEnumerable<Training> trainings)
    {
        ArgumentNullException.ThrowIfNull(trainings);

        return
        [
            .. trainings
                .OrderBy(t => t.Level)
                .ThenBy(t => t.Hours)
                .ThenBy(t => t.Title, StringComparer.OrdinalIgnoreCase)
                .ThenBy(t => t.Id),
        ];
    }

    /// <summary>
    /// Lien facultatif. Même règle que pour une offre : seuls http et https
    /// sont acceptés, un lien « javascript: » ou « file: » ouvert par
    /// l'application serait dangereux.
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
            throw new ArgumentException("Le lien d'une formation doit être une adresse http ou https.", nameof(url));
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
    /// Publique pour que l'import cherche une formation sous la forme exacte
    /// où elle a été enregistrée.
    /// </summary>
    public static string CleanText(string? value) => Clean(value);

    private static string Clean(string? value) =>
        value is null ? string.Empty : string.Join(' ', value.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
}

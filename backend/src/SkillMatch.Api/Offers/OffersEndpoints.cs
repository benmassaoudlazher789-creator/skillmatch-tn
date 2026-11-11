using System.Globalization;
using SkillMatch.Core.Jobs;
using SkillMatch.Infrastructure.Jobs;

namespace SkillMatch.Api.Offers;

/// <summary>
/// Route GET /offers : les offres classées selon les compétences du candidat.
///
/// Les compétences sont envoyées à chaque appel (choix validé) :
///   GET /offers?skill=Flutter&amp;skill=SQL&amp;limit=20
/// L'API ne les enregistre pas et ne les écrit dans aucun journal. Le
/// journal d'ASP.NET qui note l'adresse de chaque requête est réglé sur
/// « Warning » dans appsettings.json : il n'écrit donc pas ces adresses
/// (un test le vérifie).
/// </summary>
public static class OffersEndpoints
{
    /// <summary>Nom du paramètre répété dans l'adresse (?skill=…&amp;skill=…).</summary>
    public const string SkillParameter = "skill";

    public const string LimitParameter = "limit";

    /// <summary>Largement assez pour un profil réel, et l'adresse reste courte.</summary>
    public const int MaxSkills = 50;

    /// <summary>Même limite que sur l'application et dans les offres.</summary>
    public const int MaxSkillLength = JobSkill.MaxNameLength;

    public const int DefaultLimit = 20;

    public const int MaxLimit = 50;

    public static IEndpointRouteBuilder MapOffersEndpoints(this IEndpointRouteBuilder app)
    {
        // RequireAuthorization : sans jeton valide, réponse 401 avant d'entrer ici.
        app.MapGet("/offers", ListAsync).RequireAuthorization();
        return app;
    }

    private static async Task<IResult> ListAsync(
        HttpRequest request,
        JobCatalog catalog,
        CancellationToken cancellationToken)
    {
        // Lecture à la main plutôt que par paramètres liés : on choisit nous-mêmes
        // les messages d'erreur, en français et avec un code stable.
        var skillsOrError = ReadSkills(request.Query[SkillParameter]);
        if (skillsOrError.Error is { } skillError)
        {
            return Results.BadRequest(skillError);
        }

        var limitOrError = ReadLimit(request.Query[LimitParameter]);
        if (limitOrError.Error is { } limitError)
        {
            return Results.BadRequest(limitError);
        }

        var jobs = await catalog.ListAsync(cancellationToken);
        var ranked = JobRanker.Rank(jobs, skillsOrError.Skills, limitOrError.Limit);

        return Results.Ok(new OffersResponse([.. ranked.Select(ToResponse)]));
    }

    /// <summary>
    /// Compétences du candidat : vides ignorées, 50 au plus, 40 caractères
    /// chacune au plus. Une liste vide est acceptée : tous les scores valent
    /// alors 0 et les offres les plus récentes viennent d'abord.
    /// Les doublons ne gênent pas : ils donnent la même clé (voir SkillKey).
    /// </summary>
    private static (List<string> Skills, OffersErrorResponse? Error) ReadSkills(IEnumerable<string?> values)
    {
        var skills = new List<string>();
        foreach (var value in values)
        {
            var skill = value?.Trim() ?? string.Empty;
            if (skill.Length == 0)
            {
                continue;
            }

            if (skill.Length > MaxSkillLength)
            {
                // Le message ne recopie pas la compétence : une erreur ne doit
                // pas répéter les données du candidat.
                return ([], new OffersErrorResponse(
                    OffersErrorCodes.SkillTooLong,
                    $"Une compétence dépasse {MaxSkillLength} caractères."));
            }

            skills.Add(skill);
            if (skills.Count > MaxSkills)
            {
                return ([], new OffersErrorResponse(
                    OffersErrorCodes.TooManySkills,
                    $"Envoyez au plus {MaxSkills} compétences."));
            }
        }

        return (skills, null);
    }

    /// <summary>Nombre d'offres renvoyées : 20 par défaut, de 1 à 50.</summary>
    private static (int Limit, OffersErrorResponse? Error) ReadLimit(IReadOnlyList<string?> values)
    {
        if (values.Count == 0)
        {
            return (DefaultLimit, null);
        }

        if (values.Count == 1
            && int.TryParse(values[0], NumberStyles.None, CultureInfo.InvariantCulture, out var limit)
            && limit is >= 1 and <= MaxLimit)
        {
            return (limit, null);
        }

        return (0, new OffersErrorResponse(
            OffersErrorCodes.InvalidLimit,
            $"Le nombre d'offres demandé doit être un entier de 1 à {MaxLimit}."));
    }

    private static OfferResponse ToResponse(RankedJob ranked)
    {
        var (job, match) = ranked;
        return new OfferResponse(
            job.Id,
            job.Title,
            job.Company,
            JobCodes.ToCode(job.Type),
            job.City,
            job.Url,
            job.Source,
            job.IsSample,
            job.PublishedAt,
            match.Score,
            match.RequiredAcquired,
            match.RequiredMissing,
            match.PreferredAcquired,
            match.PreferredMissing,
            match.Explanation);
    }
}

using SkillMatch.Core.Skills;
using SkillMatch.Core.Trainings;
using SkillMatch.Infrastructure.Trainings;

namespace SkillMatch.Api.Trainings;

/// <summary>
/// Route GET /trainings : les formations pour apprendre UNE compétence.
///
///   GET /trainings?skill=Docker
///
/// Une seule compétence par appel (choix validé) : l'écran Formations
/// s'ouvre pour une compétence manquante précise. Comme pour /offers, la
/// compétence n'est ni enregistrée ni écrite dans un journal (le journal
/// d'ASP.NET qui note les adresses reste réglé sur « Warning », un test le
/// vérifie).
/// </summary>
public static class TrainingsEndpoints
{
    /// <summary>Nom du paramètre dans l'adresse (?skill=…).</summary>
    public const string SkillParameter = "skill";

    /// <summary>Même limite que dans les offres et sur l'application.</summary>
    public const int MaxSkillLength = Training.MaxSkillLength;

    public static IEndpointRouteBuilder MapTrainingsEndpoints(this IEndpointRouteBuilder app)
    {
        // RequireAuthorization : sans jeton valide, réponse 401 avant d'entrer ici.
        app.MapGet("/trainings", ListAsync).RequireAuthorization();
        return app;
    }

    private static async Task<IResult> ListAsync(
        HttpRequest request,
        TrainingCatalog catalog,
        CancellationToken cancellationToken)
    {
        // Lecture à la main, comme pour /offers : on choisit nous-mêmes les
        // messages d'erreur, en français et avec un code stable.
        var skillOrError = ReadSkill(request.Query[SkillParameter]);
        if (skillOrError.Error is { } error)
        {
            return Results.BadRequest(error);
        }

        var skill = skillOrError.Skill;

        // Même clé que pour le dictionnaire et le score : « docker », « JS »
        // ou « k8s » retrouvent Docker, JavaScript et Kubernetes.
        var trainings = await catalog.ForSkillAsync(SkillKey.For(skill), cancellationToken);

        return Results.Ok(new TrainingsResponse(skill, [.. trainings.Select(ToResponse)]));
    }

    /// <summary>
    /// Exactement une compétence, non vide, de 40 caractères au plus, et
    /// contenant au moins un mot (« !!! » est refusé : sa clé serait vide).
    /// Les messages ne recopient jamais la compétence : une erreur ne doit
    /// pas répéter les données du candidat.
    /// </summary>
    private static (string Skill, TrainingsErrorResponse? Error) ReadSkill(IReadOnlyList<string?> values)
    {
        if (values.Count > 1)
        {
            return (string.Empty, new TrainingsErrorResponse(
                TrainingsErrorCodes.TooManySkills,
                "Envoyez une seule compétence à la fois."));
        }

        var skill = values.Count == 1 ? values[0]?.Trim() ?? string.Empty : string.Empty;
        if (skill.Length > MaxSkillLength)
        {
            return (string.Empty, new TrainingsErrorResponse(
                TrainingsErrorCodes.SkillTooLong,
                $"La compétence dépasse {MaxSkillLength} caractères."));
        }

        if (skill.Length == 0 || SkillKey.For(skill).Length == 0)
        {
            return (string.Empty, new TrainingsErrorResponse(
                TrainingsErrorCodes.MissingSkill,
                "Indiquez la compétence pour laquelle chercher des formations."));
        }

        return (skill, null);
    }

    private static TrainingResponse ToResponse(Training training) =>
        new(
            training.Id,
            training.Skill,
            training.Title,
            TrainingCodes.ToCode(training.Level),
            training.Hours,
            TrainingCodes.ToCode(training.Type),
            training.Url,
            training.Source,
            training.IsSample);
}

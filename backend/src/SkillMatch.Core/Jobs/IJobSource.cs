namespace SkillMatch.Core.Jobs;

/// <summary>
/// Une source d'offres : le jeu d'exemple aujourd'hui, une vraie source plus
/// tard (flux d'un partenaire, fichier fourni par une école…).
///
/// Pourquoi une interface ? Le reste de l'API (import, score, route
/// GET /offers) ne dépend d'aucune source précise : brancher une nouvelle
/// source, c'est écrire une classe qui implémente cette interface, sans
/// toucher au reste. Aucune dépendance à un site d'annonces n'est écrite
/// dans le code.
/// </summary>
public interface IJobSource
{
    /// <summary>
    /// Nom court et stable de la source (« exemple »…), enregistré avec
    /// chaque offre. Avec <see cref="JobPosting.ExternalId"/>, il identifie
    /// une offre d'un import à l'autre.
    /// </summary>
    string Name { get; }

    /// <summary>Vrai si les offres sont fictives : l'application l'affiche alors.</summary>
    bool IsSample { get; }

    /// <summary>Renvoie les offres actuellement publiées par la source.</summary>
    Task<IReadOnlyList<JobPosting>> FetchAsync(CancellationToken cancellationToken);
}

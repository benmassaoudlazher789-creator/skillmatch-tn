namespace SkillMatch.Core.Trainings;

/// <summary>
/// Une source de formations : le jeu d'exemple aujourd'hui, une vraie source
/// plus tard (catalogue fourni par une école, un partenaire…).
///
/// Même idée que IJobSource : l'import et la route GET /trainings ne
/// dépendent d'aucune source précise. Brancher une nouvelle source, c'est
/// écrire une classe qui implémente cette interface, sans toucher au reste.
/// Aucune dépendance à un site d'annonces ou de formations n'est écrite
/// dans le code.
/// </summary>
public interface ITrainingSource
{
    /// <summary>
    /// Nom court et stable de la source (« exemple »…), enregistré avec
    /// chaque formation. Avec <see cref="TrainingPosting.ExternalId"/>, il
    /// identifie une formation d'un import à l'autre.
    /// </summary>
    string Name { get; }

    /// <summary>Vrai si les formations sont fictives : l'application l'affiche alors.</summary>
    bool IsSample { get; }

    /// <summary>Renvoie les formations actuellement proposées par la source.</summary>
    Task<IReadOnlyList<TrainingPosting>> FetchAsync(CancellationToken cancellationToken);
}

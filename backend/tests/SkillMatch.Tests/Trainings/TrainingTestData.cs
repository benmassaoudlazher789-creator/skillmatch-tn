using SkillMatch.Core.Trainings;

namespace SkillMatch.Tests.Trainings;

/// <summary>Formations fictives pour les tests, toutes valides par défaut.</summary>
internal static class TrainingTestData
{
    public static TrainingPosting Posting(
        string externalId = "formation-001",
        string skill = "Docker",
        string title = "Formation exemple",
        TrainingLevel level = TrainingLevel.Debutant,
        int hours = 3,
        TrainingType type = TrainingType.Tutoriel,
        string? url = null) =>
        new(externalId, skill, title, level, hours, type, url);
}

/// <summary>
/// Source de formations pour les tests : renvoie les formations qu'on lui
/// donne. Chaque test choisit un nom de source différent, pour ne pas
/// mélanger ses formations avec celles d'un autre test dans la même base.
/// </summary>
internal sealed class TestTrainingSource(string name, params TrainingPosting[] postings) : ITrainingSource
{
    public string Name => name;

    public bool IsSample => false;

    public Task<IReadOnlyList<TrainingPosting>> FetchAsync(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<TrainingPosting>>(postings);
}

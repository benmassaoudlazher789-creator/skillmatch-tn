using SkillMatch.Core.Jobs;

namespace SkillMatch.Tests.Jobs;

/// <summary>
/// Source d'offres pour les tests : renvoie les offres qu'on lui donne.
/// Chaque test choisit un nom de source différent, pour ne pas mélanger ses
/// offres avec celles d'un autre test dans la même base.
/// </summary>
internal sealed class TestJobSource(string name, params JobPosting[] postings) : IJobSource
{
    public string Name => name;

    public bool IsSample => false;

    public Task<IReadOnlyList<JobPosting>> FetchAsync(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<JobPosting>>(postings);
}

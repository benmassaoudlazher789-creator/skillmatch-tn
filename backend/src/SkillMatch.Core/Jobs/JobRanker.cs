namespace SkillMatch.Core.Jobs;

/// <summary>Une offre et son score pour un candidat.</summary>
public sealed record RankedJob(Job Job, JobMatch Match);

/// <summary>
/// Classe les offres pour un candidat. Fonction pure, testée sans base.
///
/// Ordre : meilleur score d'abord ; à score égal, l'offre la plus récente ;
/// puis l'Id, pour que l'ordre soit toujours le même d'un appel à l'autre.
/// </summary>
public static class JobRanker
{
    public static IReadOnlyList<RankedJob> Rank(IEnumerable<Job> jobs, IEnumerable<string> candidateSkills, int limit)
    {
        ArgumentNullException.ThrowIfNull(jobs);
        ArgumentNullException.ThrowIfNull(candidateSkills);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(limit);

        var keys = MatchScorer.CandidateKeys(candidateSkills);

        return jobs
            .Select(job => new RankedJob(job, MatchScorer.Score(job, keys)))
            .OrderByDescending(r => r.Match.Score)
            .ThenByDescending(r => r.Job.PublishedAt)
            .ThenBy(r => r.Job.Id)
            .Take(limit)
            .ToList();
    }
}

using SkillMatch.Core.Jobs;

namespace SkillMatch.Tests.Jobs;

/// <summary>Offres fictives pour les tests, toutes valides par défaut.</summary>
internal static class JobTestData
{
    public static JobPosting Posting(
        string externalId = "test-001",
        string title = "Stage exemple",
        JobType type = JobType.Stage,
        string? url = "https://example.com/offre-test",
        DateTimeOffset? publishedAt = null,
        string[]? required = null,
        string[]? preferred = null) =>
        new(
            externalId,
            title,
            "Société Exemple Test",
            type,
            "Tunis",
            url,
            publishedAt ?? new DateTimeOffset(2026, 10, 1, 9, 0, 0, TimeSpan.Zero),
            required ?? ["Flutter", "Dart"],
            preferred ?? ["Git"]);

    public static Job Job(
        string externalId = "test-001",
        DateTimeOffset? publishedAt = null,
        string[]? required = null,
        string[]? preferred = null) =>
        Core.Jobs.Job.FromPosting(
            "test",
            isSample: true,
            Posting(externalId, publishedAt: publishedAt, required: required, preferred: preferred));
}

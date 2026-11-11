using SkillMatch.Core.Jobs;

namespace SkillMatch.Tests.Jobs;

public sealed class JobRankerTests
{
    private static readonly DateTimeOffset Older = new(2026, 9, 1, 9, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset Newer = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void MeilleurScoreDAbord_PuisLePlusRecent()
    {
        var python = JobTestData.Job("python", Newer, required: ["Python"], preferred: ["SQL"]);
        var flutterOld = JobTestData.Job("flutter-ancienne", Older, required: ["Flutter"], preferred: ["Git"]);
        var flutterNew = JobTestData.Job("flutter-recente", Newer, required: ["Flutter"], preferred: ["Git"]);

        var ranked = JobRanker.Rank([python, flutterOld, flutterNew], ["Flutter", "Git"], limit: 10);

        // Les deux offres Flutter ont 100 % : la plus récente passe devant.
        Assert.Equal(
            new[] { "flutter-recente", "flutter-ancienne", "python" },
            ranked.Select(r => r.Job.ExternalId));
        Assert.Equal(new[] { 100, 100, 0 }, ranked.Select(r => r.Match.Score));
    }

    [Fact]
    public void LimiteRespectee()
    {
        var jobs = Enumerable.Range(1, 5).Select(i => JobTestData.Job($"offre-{i}")).ToList();

        Assert.Equal(2, JobRanker.Rank(jobs, ["Flutter"], limit: 2).Count);
    }

    [Fact]
    public void OrdreToujoursLeMeme()
    {
        // Même score et même date : l'Id départage, l'ordre ne change pas.
        var jobs = Enumerable.Range(1, 6).Select(i => JobTestData.Job($"offre-{i}")).ToList();

        var first = JobRanker.Rank(jobs, [], 10).Select(r => r.Job.Id).ToList();
        var reversed = JobRanker.Rank(Enumerable.Reverse(jobs), [], 10).Select(r => r.Job.Id).ToList();

        Assert.Equal(first, reversed);
    }

    [Fact]
    public void AucuneOffre_AucunResultat() =>
        // Repris du test mobile (match_score_test.dart).
        Assert.Empty(JobRanker.Rank([], ["Dart"], 10));

    [Fact]
    public void LimiteNulle_Refusee() =>
        Assert.Throws<ArgumentOutOfRangeException>(() => JobRanker.Rank([], [], 0));
}

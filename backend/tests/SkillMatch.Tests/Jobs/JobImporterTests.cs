using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SkillMatch.Core.Jobs;
using SkillMatch.Infrastructure.Jobs;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Tests.Jobs;

/// <summary>Import des offres dans la base SQLite en mémoire de l'API de test.</summary>
public sealed class JobImporterTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    [Fact]
    public async Task ImportDeuxFois_AucunDoublon()
    {
        var source = new TestJobSource(
            NewSourceName(),
            JobTestData.Posting("a"),
            JobTestData.Posting("b"));

        var first = await ImportAsync(source);
        var second = await ImportAsync(source);

        Assert.Equal(new JobImportResult(Added: 2, Updated: 0, Rejected: 0), first);
        Assert.Equal(new JobImportResult(Added: 0, Updated: 2, Rejected: 0), second);
        Assert.Equal(2, (await JobsOfAsync(source.Name)).Count);
    }

    [Fact]
    public async Task NouvelImport_MetAJourTitreEtCompetences()
    {
        var name = NewSourceName();
        await ImportAsync(new TestJobSource(
            name,
            JobTestData.Posting("a", title: "Ancien titre", required: ["Flutter", "Dart"], preferred: ["Git"])));

        await ImportAsync(new TestJobSource(
            name,
            JobTestData.Posting("a", title: "Nouveau titre", required: ["Flutter"], preferred: ["Dart", "Firebase"])));

        var job = Assert.Single(await JobsOfAsync(name));
        Assert.Equal("Nouveau titre", job.Title);
        var skills = job.Skills.ToDictionary(s => s.Name, s => s.Importance);
        Assert.Equal(3, skills.Count);
        Assert.Equal(SkillImportance.Required, skills["Flutter"]);
        Assert.Equal(SkillImportance.Preferred, skills["Dart"]);
        Assert.Equal(SkillImportance.Preferred, skills["Firebase"]);
    }

    [Fact]
    public async Task OffreInvalide_EcarteeSansBloquerLesAutres()
    {
        var source = new TestJobSource(
            NewSourceName(),
            JobTestData.Posting("valide"),
            JobTestData.Posting("lien-dangereux", url: "javascript:alert(1)"),
            JobTestData.Posting("sans-competence", required: [], preferred: []));

        var result = await ImportAsync(source);

        Assert.Equal(new JobImportResult(Added: 1, Updated: 0, Rejected: 2), result);
        Assert.Equal("valide", Assert.Single(await JobsOfAsync(source.Name)).ExternalId);
    }

    [Fact]
    public async Task MemeIdentifiantDeuxFois_LaPremiereEstGardee()
    {
        var source = new TestJobSource(
            NewSourceName(),
            JobTestData.Posting("a", title: "Premier"),
            JobTestData.Posting(" a ", title: "Second"));

        var result = await ImportAsync(source);

        Assert.Equal(new JobImportResult(Added: 1, Updated: 0, Rejected: 1), result);
        Assert.Equal("Premier", Assert.Single(await JobsOfAsync(source.Name)).Title);
    }

    [Fact]
    public async Task JeuDExemple_ImporteEtMarque()
    {
        var result = await ImportAsync(new SampleJobSource());

        Assert.Equal(SampleJobSource.Postings.Count, result.Added + result.Updated);
        Assert.Equal(0, result.Rejected);
        var jobs = await JobsOfAsync(SampleJobSource.SourceName);
        Assert.Equal(SampleJobSource.Postings.Count, jobs.Count);
        Assert.All(jobs, j => Assert.True(j.IsSample));
    }

    // ---- Outils ----

    private static string NewSourceName() => $"test-{Guid.NewGuid():N}";

    private async Task<JobImportResult> ImportAsync(IJobSource source)
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var importer = scope.ServiceProvider.GetRequiredService<JobImporter>();
        return await importer.ImportAsync(source, TestContext.Current.CancellationToken);
    }

    /// <summary>Relit les offres dans un NOUVEAU scope : on voit ce qui est vraiment en base.</summary>
    private async Task<List<Job>> JobsOfAsync(string source)
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<SkillMatchDbContext>();
        return await db.Jobs
            .AsNoTracking()
            .Include(j => j.Skills)
            .Where(j => j.Source == source)
            .ToListAsync(TestContext.Current.CancellationToken);
    }
}

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SkillMatch.Core.Trainings;
using SkillMatch.Infrastructure.Persistence;
using SkillMatch.Infrastructure.Trainings;

namespace SkillMatch.Tests.Trainings;

/// <summary>Import des formations dans la base SQLite en mémoire de l'API de test.</summary>
public sealed class TrainingImporterTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    [Fact]
    public async Task ImportDeuxFois_AucunDoublon()
    {
        var source = new TestTrainingSource(
            NewSourceName(),
            TrainingTestData.Posting("a"),
            TrainingTestData.Posting("b"));

        var first = await ImportAsync(source);
        var second = await ImportAsync(source);

        Assert.Equal(new TrainingImportResult(Added: 2, Updated: 0, Rejected: 0), first);
        Assert.Equal(new TrainingImportResult(Added: 0, Updated: 2, Rejected: 0), second);
        Assert.Equal(2, (await TrainingsOfAsync(source.Name)).Count);
    }

    [Fact]
    public async Task NouvelImport_MetAJour()
    {
        var name = NewSourceName();
        await ImportAsync(new TestTrainingSource(
            name,
            TrainingTestData.Posting("a", skill: "Docker", title: "Ancien titre", hours: 3)));

        await ImportAsync(new TestTrainingSource(
            name,
            TrainingTestData.Posting("a", skill: "k8s", title: "Nouveau titre", hours: 5,
                level: TrainingLevel.Avance, type: TrainingType.ProjetPratique)));

        var training = Assert.Single(await TrainingsOfAsync(name));
        Assert.Equal("Nouveau titre", training.Title);
        Assert.Equal("k8s", training.Skill);
        Assert.Equal("kubernetes", training.SkillKey);
        Assert.Equal(5, training.Hours);
        Assert.Equal(TrainingLevel.Avance, training.Level);
        Assert.Equal(TrainingType.ProjetPratique, training.Type);
    }

    [Fact]
    public async Task FormationInvalide_EcarteeSansBloquerLesAutres()
    {
        var source = new TestTrainingSource(
            NewSourceName(),
            TrainingTestData.Posting("valide"),
            TrainingTestData.Posting("lien-dangereux", url: "javascript:alert(1)"),
            TrainingTestData.Posting("sans-duree", hours: 0));

        var result = await ImportAsync(source);

        Assert.Equal(new TrainingImportResult(Added: 1, Updated: 0, Rejected: 2), result);
        Assert.Equal("valide", Assert.Single(await TrainingsOfAsync(source.Name)).ExternalId);
    }

    [Fact]
    public async Task MemeIdentifiantDeuxFois_LaPremiereEstGardee()
    {
        var source = new TestTrainingSource(
            NewSourceName(),
            TrainingTestData.Posting("a", title: "Première"),
            TrainingTestData.Posting(" a ", title: "Seconde"));

        var result = await ImportAsync(source);

        Assert.Equal(new TrainingImportResult(Added: 1, Updated: 0, Rejected: 1), result);
        Assert.Equal("Première", Assert.Single(await TrainingsOfAsync(source.Name)).Title);
    }

    [Fact]
    public async Task JeuDExemple_ImporteEtMarque()
    {
        var result = await ImportAsync(new SampleTrainingSource());

        Assert.Equal(SampleTrainingSource.Postings.Count, result.Added + result.Updated);
        Assert.Equal(0, result.Rejected);
        var trainings = await TrainingsOfAsync(SampleTrainingSource.SourceName);
        Assert.Equal(SampleTrainingSource.Postings.Count, trainings.Count);
        Assert.All(trainings, t => Assert.True(t.IsSample));
    }

    // ---- Outils ----

    private static string NewSourceName() => $"test-{Guid.NewGuid():N}";

    private async Task<TrainingImportResult> ImportAsync(ITrainingSource source)
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var importer = scope.ServiceProvider.GetRequiredService<TrainingImporter>();
        return await importer.ImportAsync(source, TestContext.Current.CancellationToken);
    }

    /// <summary>Relit les formations dans un NOUVEAU scope : on voit ce qui est vraiment en base.</summary>
    private async Task<List<Training>> TrainingsOfAsync(string source)
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<SkillMatchDbContext>();
        return await db.Trainings
            .AsNoTracking()
            .Where(t => t.Source == source)
            .ToListAsync(TestContext.Current.CancellationToken);
    }
}

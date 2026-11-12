using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SkillMatch.Api.Auth;
using SkillMatch.Api.Trainings;
using SkillMatch.Core.Trainings;
using SkillMatch.Core.Users;
using SkillMatch.Infrastructure.Trainings;

namespace SkillMatch.Tests.Trainings;

/// <summary>
/// Tests de bout en bout de GET /trainings. Cette classe a sa propre API et
/// sa propre base : on y importe quelques formations fictives connues.
/// </summary>
public sealed class TrainingsEndpointsTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    // Formes attendues des réponses, écrites ici plutôt que reprises de l'API.
    private sealed record TrainingsBody(string Skill, List<TrainingBody> Trainings);

    private sealed record TrainingBody(
        Guid Id,
        string Skill,
        string Title,
        string Level,
        int Hours,
        string Type,
        string? Url,
        string Source,
        bool IsSample);

    private sealed record ErrorBody(string Code, string Title);

    private const string SourceName = "test-formations";

    // Trois formations Docker dans le désordre, pour vérifier le tri.
    private static readonly TrainingPosting[] Postings =
    [
        TrainingTestData.Posting("docker-avance", "Docker", "Docker en équipe",
            TrainingLevel.Intermediaire, 6, TrainingType.ProjetPratique),
        TrainingTestData.Posting("docker-zeta", "Docker", "Zeta des conteneurs",
            TrainingLevel.Debutant, 3, TrainingType.CoursEnLigne),
        TrainingTestData.Posting("docker-alpha", "Docker", "alpha des conteneurs",
            TrainingLevel.Debutant, 3, TrainingType.Tutoriel, url: "https://example.com/formation-test"),
        TrainingTestData.Posting("js", "JavaScript", "Les bases de JavaScript",
            TrainingLevel.Debutant, 6, TrainingType.CoursEnLigne),
        TrainingTestData.Posting("k8s", "Kubernetes", "Déployer sur un petit cluster",
            TrainingLevel.Avance, 10, TrainingType.ProjetPratique),
    ];

    // ---- Jeton ----

    [Fact]
    public async Task SansJeton_401()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/trainings?skill=Docker", ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ---- Résultats ----

    [Fact]
    public async Task TrieesParNiveauDureeEtTitre()
    {
        var body = await GetOkAsync("Docker");

        Assert.Equal("Docker", body.Skill);
        Assert.Equal(
            new[] { "alpha des conteneurs", "Zeta des conteneurs", "Docker en équipe" },
            body.Trainings.Select(t => t.Title));
    }

    [Fact]
    public async Task ChampsRenvoyes()
    {
        var body = await GetOkAsync("Docker");

        var first = body.Trainings[0];
        Assert.NotEqual(Guid.Empty, first.Id);
        Assert.Equal("Docker", first.Skill);
        Assert.Equal("debutant", first.Level);
        Assert.Equal(3, first.Hours);
        Assert.Equal("tutoriel", first.Type);
        Assert.Equal("https://example.com/formation-test", first.Url);
        Assert.Equal(SourceName, first.Source);
        Assert.False(first.IsSample);

        var last = body.Trainings[2];
        Assert.Equal("intermediaire", last.Level);
        Assert.Equal("projet_pratique", last.Type);
        Assert.Null(body.Trainings[1].Url);
    }

    [Theory]
    [InlineData("docker", "Docker")]
    [InlineData("  DOCKER  ", "Docker")]
    [InlineData("JS", "JavaScript")]
    [InlineData("k8s", "Kubernetes")]
    public async Task ComparaisonSouple_CommeLeDictionnaire(string sent, string expectedSkill)
    {
        var body = await GetOkAsync(sent);

        Assert.NotEmpty(body.Trainings);
        Assert.All(body.Trainings, t => Assert.Equal(expectedSkill, t.Skill));
        // La compétence renvoyée est celle envoyée, simplement nettoyée.
        Assert.Equal(sent.Trim(), body.Skill);
    }

    [Fact]
    public async Task CompetenceSansFormation_ListeVide200()
    {
        var body = await GetOkAsync("Windows");

        Assert.Equal("Windows", body.Skill);
        Assert.Empty(body.Trainings);
    }

    // ---- Erreurs ----

    [Theory]
    [InlineData("")]
    [InlineData("skill=")]
    [InlineData("skill=%20%20")]
    [InlineData("skill=---")]
    public Task CompetenceAbsente_400(string query) =>
        AssertErrorAsync(query, TrainingsErrorCodes.MissingSkill);

    [Fact]
    public Task PlusieursCompetences_400() =>
        AssertErrorAsync("skill=Docker&skill=Python", TrainingsErrorCodes.TooManySkills);

    [Fact]
    public Task CompetenceTropLongue_400() =>
        AssertErrorAsync(
            $"skill={new string('x', TrainingsEndpoints.MaxSkillLength + 1)}",
            TrainingsErrorCodes.SkillTooLong);

    [Fact]
    public async Task CompetenceDeQuaranteCaracteres_Acceptee()
    {
        var body = await GetOkAsync(new string('x', TrainingsEndpoints.MaxSkillLength));

        Assert.Empty(body.Trainings);
    }

    // ---- Confidentialité des journaux ----

    [Fact]
    public async Task Journaux_SansLaCompetence()
    {
        var ct = TestContext.Current.CancellationToken;
        var logs = new CapturingLoggerProvider();
        using var loggedFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureLogging(logging => logging.AddProvider(logs)));
        using var client = loggedFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(loggedFactory));

        // Marqueur fictif : il ne doit apparaître dans AUCUN message.
        const string marker = "MarqueurCompetenceExemple";
        using var ok = await client.GetAsync($"/trainings?skill={marker}", ct);
        using var refused = await client.GetAsync($"/trainings?skill={marker}&skill={marker}", ct);

        Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
        foreach (var message in logs.Messages)
        {
            Assert.DoesNotContain(marker, message, StringComparison.OrdinalIgnoreCase);
        }
    }

    // ---- Outils ----

    /// <summary>Importe les formations de test (sans doublon, même appelé à chaque test).</summary>
    private async Task SeedAsync()
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var importer = scope.ServiceProvider.GetRequiredService<TrainingImporter>();
        await importer.ImportAsync(new TestTrainingSource(SourceName, Postings), TestContext.Current.CancellationToken);
    }

    private async Task<TrainingsBody> GetOkAsync(string skill)
    {
        var ct = TestContext.Current.CancellationToken;
        await SeedAsync();
        using var client = AuthorizedClient();

        using var response = await client.GetAsync(
            $"/trainings?{TrainingsEndpoints.SkillParameter}={Uri.EscapeDataString(skill)}", ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<TrainingsBody>(ct);
        Assert.NotNull(body);
        return body;
    }

    private async Task AssertErrorAsync(string query, string expectedCode)
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = AuthorizedClient();

        using var response = await client.GetAsync($"/trainings?{query}", ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ErrorBody>(ct);
        Assert.NotNull(body);
        Assert.Equal(expectedCode, body.Code);
        Assert.False(string.IsNullOrWhiteSpace(body.Title));
    }

    private HttpClient AuthorizedClient()
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(factory));
        return client;
    }

    /// <summary>
    /// Jeton valide pour un compte d'exemple. Le compte n'est pas en base :
    /// /trainings ne lit que le jeton signé, pas la table users.
    /// </summary>
    private static string CreateToken(WebApplicationFactory<Program> apiFactory)
    {
        var user = User.Create("Candidat Exemple", $"candidat-{Guid.NewGuid():N}@exemple.tn", "hash-exemple");
        return apiFactory.Services.GetRequiredService<TokenService>().CreateToken(user);
    }
}

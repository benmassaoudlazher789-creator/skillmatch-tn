using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SkillMatch.Api.Auth;
using SkillMatch.Api.Offers;
using SkillMatch.Core.Jobs;
using SkillMatch.Core.Users;
using SkillMatch.Infrastructure.Jobs;
using SkillMatch.Tests.Jobs;

namespace SkillMatch.Tests.Offers;

/// <summary>
/// Tests de bout en bout de GET /offers. Chaque classe de tests a sa propre
/// API et sa propre base : on y importe trois offres fictives connues.
/// </summary>
public sealed class OffersEndpointsTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    // Formes attendues des réponses, écrites ici plutôt que reprises de l'API.
    private sealed record OffersBody(List<OfferBody> Offers);

    private sealed record OfferBody(
        Guid Id,
        string Title,
        string Company,
        string Type,
        string City,
        string? Url,
        string Source,
        bool IsSample,
        DateTimeOffset PublishedAt,
        int Score,
        List<string> RequiredAcquired,
        List<string> RequiredMissing,
        List<string> PreferredAcquired,
        List<string> PreferredMissing,
        string Explanation);

    private sealed record ErrorBody(string Code, string Title);

    private const string SourceName = "test-offres";

    // Trois offres fictives, chacune avec une date différente.
    private static readonly JobPosting[] Postings =
    [
        JobTestData.Posting("mobile", "Stage mobile", JobType.Stage,
            publishedAt: new DateTimeOffset(2026, 10, 10, 9, 0, 0, TimeSpan.Zero),
            required: ["Flutter", "Dart"], preferred: ["Git"]),
        JobTestData.Posting("donnees", "Emploi données", JobType.Emploi,
            publishedAt: new DateTimeOffset(2026, 10, 20, 9, 0, 0, TimeSpan.Zero),
            required: ["Python", "SQL"], preferred: ["Power BI"]),
        JobTestData.Posting("reseau", "PFE réseau", JobType.Pfe,
            publishedAt: new DateTimeOffset(2026, 10, 15, 9, 0, 0, TimeSpan.Zero),
            required: ["Linux", "Réseaux"], preferred: []),
    ];

    // ---- Jeton ----

    [Fact]
    public async Task SansJeton_401()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/offers?skill=Flutter", ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ---- Classement et explication ----

    [Fact]
    public async Task TriesParScore_PuisParDate()
    {
        var body = await GetOkAsync("Flutter", "Dart");

        Assert.Equal(new[] { "Stage mobile", "Emploi données", "PFE réseau" }, body.Offers.Select(o => o.Title));
        // Requises 2/2 (70 %), souhaitée 0/1 : 70. Les autres : 0, la plus récente d'abord.
        Assert.Equal(new[] { 70, 0, 0 }, body.Offers.Select(o => o.Score));
    }

    [Fact]
    public async Task ListesAcquisesManquantesEtExplication()
    {
        var body = await GetOkAsync("flutter", "Git");

        var offer = body.Offers[0];
        Assert.Equal("Stage mobile", offer.Title);
        // 70 × 1/2 + 30 × 1/1 = 65.
        Assert.Equal(65, offer.Score);
        Assert.Equal(new[] { "Flutter" }, offer.RequiredAcquired);
        Assert.Equal(new[] { "Dart" }, offer.RequiredMissing);
        Assert.Equal(new[] { "Git" }, offer.PreferredAcquired);
        Assert.Empty(offer.PreferredMissing);
        Assert.Equal("Requises : 1 sur 2 (70 % du score) · Souhaitées : 1 sur 1 (30 %)", offer.Explanation);
        Assert.Equal("stage", offer.Type);
        Assert.Equal(SourceName, offer.Source);
        Assert.False(offer.IsSample);
        Assert.Equal("https://example.com/offre-test", offer.Url);
    }

    [Fact]
    public async Task ComparaisonSouple_AccentsEtVariantes()
    {
        // « reseaux » sans accent, « ubuntu » est une variante de Linux.
        var body = await GetOkAsync("reseaux", "ubuntu");

        var offer = body.Offers[0];
        Assert.Equal("PFE réseau", offer.Title);
        Assert.Equal(100, offer.Score);
        Assert.Equal("Requises : 2 sur 2 (100 % du score)", offer.Explanation);
    }

    [Fact]
    public async Task SansCompetence_ToutA0_LesPlusRecentesDAbord()
    {
        var body = await GetOkAsync();

        Assert.Equal(new[] { "Emploi données", "PFE réseau", "Stage mobile" }, body.Offers.Select(o => o.Title));
        Assert.All(body.Offers, o => Assert.Equal(0, o.Score));
    }

    [Fact]
    public async Task Limite()
    {
        var body = await GetOkWithQueryAsync("limit=1&skill=Python");

        Assert.Equal("Emploi données", Assert.Single(body.Offers).Title);
    }

    // ---- Erreurs ----

    [Theory]
    [InlineData("limit=0")]
    [InlineData("limit=51")]
    [InlineData("limit=abc")]
    [InlineData("limit=-1")]
    [InlineData("limit=1&limit=2")]
    public Task LimiteInvalide_400(string query) =>
        AssertErrorAsync(query, OffersErrorCodes.InvalidLimit);

    [Fact]
    public Task TropDeCompetences_400() =>
        AssertErrorAsync(
            Query(Enumerable.Range(1, OffersEndpoints.MaxSkills + 1).Select(i => $"Outil{i}")),
            OffersErrorCodes.TooManySkills);

    [Fact]
    public Task CompetenceTropLongue_400() =>
        AssertErrorAsync(Query([new string('x', OffersEndpoints.MaxSkillLength + 1)]), OffersErrorCodes.SkillTooLong);

    [Fact]
    public async Task CinquanteCompetences_Acceptees()
    {
        var body = await GetOkWithQueryAsync(
            Query(Enumerable.Range(1, OffersEndpoints.MaxSkills).Select(i => $"Outil{i}")));

        Assert.Equal(3, body.Offers.Count);
    }

    // ---- Confidentialité des journaux ----

    [Fact]
    public async Task Journaux_SansLesCompetences()
    {
        var ct = TestContext.Current.CancellationToken;
        var logs = new CapturingLoggerProvider();
        using var loggedFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureLogging(logging => logging.AddProvider(logs)));
        using var client = loggedFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(loggedFactory));

        // Marqueur fictif : il ne doit apparaître dans AUCUN message.
        const string marker = "MarqueurCompetenceExemple";
        using var ok = await client.GetAsync($"/offers?skill={marker}", ct);
        using var refused = await client.GetAsync($"/offers?skill={marker}&limit=0", ct);

        Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
        foreach (var message in logs.Messages)
        {
            Assert.DoesNotContain(marker, message, StringComparison.OrdinalIgnoreCase);
        }
    }

    // ---- Outils ----

    /// <summary>Importe les trois offres de test (sans doublon, même appelé à chaque test).</summary>
    private async Task SeedAsync()
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var importer = scope.ServiceProvider.GetRequiredService<JobImporter>();
        await importer.ImportAsync(new TestJobSource(SourceName, Postings), TestContext.Current.CancellationToken);
    }

    private static string Query(IEnumerable<string> skills) =>
        string.Join('&', skills.Select(s => $"{OffersEndpoints.SkillParameter}={Uri.EscapeDataString(s)}"));

    private Task<OffersBody> GetOkAsync(params string[] skills) => GetOkWithQueryAsync(Query(skills));

    private async Task<OffersBody> GetOkWithQueryAsync(string query)
    {
        var ct = TestContext.Current.CancellationToken;
        await SeedAsync();
        using var client = AuthorizedClient();

        using var response = await client.GetAsync($"/offers?{query}", ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<OffersBody>(ct);
        Assert.NotNull(body);
        return body;
    }

    private async Task AssertErrorAsync(string query, string expectedCode)
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = AuthorizedClient();

        using var response = await client.GetAsync($"/offers?{query}", ct);

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
    /// /offers ne lit que le jeton signé, pas la table users.
    /// </summary>
    private static string CreateToken(WebApplicationFactory<Program> apiFactory)
    {
        var user = User.Create("Candidat Exemple", $"candidat-{Guid.NewGuid():N}@exemple.tn", "hash-exemple");
        return apiFactory.Services.GetRequiredService<TokenService>().CreateToken(user);
    }
}

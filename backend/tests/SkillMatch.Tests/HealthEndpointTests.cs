using System.Net;
using System.Net.Http.Json;

namespace SkillMatch.Tests;

public sealed class HealthEndpointTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    // Forme attendue de la réponse ; la lecture JSON ignore la casse (status / Status).
    private sealed record HealthResponse(string Status);

    [Fact]
    public async Task GetHealth_RetourneOk()
    {
        // Le jeton d'annulation de xUnit arrête proprement la requête si le test
        // est interrompu (l'analyseur xUnit1051 le demande).
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health", ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);

        var body = await response.Content.ReadFromJsonAsync<HealthResponse>(ct);
        Assert.NotNull(body);
        Assert.Equal("ok", body.Status);
    }
}

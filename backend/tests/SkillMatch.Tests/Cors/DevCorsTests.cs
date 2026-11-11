using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using SkillMatch.Api.Cors;

namespace SkillMatch.Tests.Cors;

/// <summary>
/// CORS : actif en Development pour localhost seulement, absent ailleurs.
///
/// La factory de base tourne en « Testing ». Pour tester le mode
/// développement, on crée une copie de l'API en « Development ». Les réglages
/// de test (clé JWT aléatoire, SQLite en mémoire) restent appliqués : rien ne
/// dépend de PostgreSQL ni des user-secrets de la machine.
/// </summary>
public sealed class DevCorsTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    // Port quelconque, comme celui que choisit « flutter run -d chrome ».
    private const string FlutterWebOrigin = "http://localhost:53124";

    private const string AllowOriginHeader = "Access-Control-Allow-Origin";

    // ---- Règle pure, sans serveur ----

    [Theory]
    [InlineData("http://localhost:53124")]
    [InlineData("http://localhost")]
    [InlineData("http://127.0.0.1:8080")]
    [InlineData("https://localhost:5001")]
    public void IsLocalhostOrigin_AccepteLocalhost(string origin) =>
        Assert.True(DevCors.IsLocalhostOrigin(origin));

    [Theory]
    [InlineData("http://exemple.com")]
    // Commence par « http://localhost » mais l'hôte est exemple.com.
    [InlineData("http://localhost.exemple.com")]
    [InlineData("http://exemple.com/localhost")]
    [InlineData("ftp://localhost")]
    [InlineData("null")]
    [InlineData("")]
    public void IsLocalhostOrigin_RefuseLeReste(string origin) =>
        Assert.False(DevCors.IsLocalhostOrigin(origin));

    // ---- Comportement de l'API ----

    [Fact]
    public async Task Development_PreflightDepuisLocalhost_EstAutorise()
    {
        var ct = TestContext.Current.CancellationToken;
        using var devFactory = CreateFactory("Development");
        using var client = devFactory.CreateClient();

        using var response = await client.SendAsync(Preflight(FlutterWebOrigin), ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal(FlutterWebOrigin, AllowOrigin(response));
    }

    [Fact]
    public async Task Development_PreflightVersCvAvecJeton_EstAutorise()
    {
        var ct = TestContext.Current.CancellationToken;
        using var devFactory = CreateFactory("Development");
        using var client = devFactory.CreateClient();

        // L'envoi du CV porte l'en-tête Authorization : Chrome demande d'abord
        // la permission pour cet en-tête.
        using var request = new HttpRequestMessage(HttpMethod.Options, "/cv");
        request.Headers.Add("Origin", FlutterWebOrigin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "authorization");

        using var response = await client.SendAsync(request, ct);

        Assert.Equal(FlutterWebOrigin, AllowOrigin(response));
        Assert.True(response.Headers.TryGetValues("Access-Control-Allow-Headers", out var headers));
        Assert.Contains("authorization", string.Join(",", headers), StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("http://exemple.com")]
    [InlineData("http://localhost.exemple.com")]
    public async Task Development_AutreOrigine_SansEnTeteCors(string origin)
    {
        var ct = TestContext.Current.CancellationToken;
        using var devFactory = CreateFactory("Development");
        using var client = devFactory.CreateClient();

        using var response = await client.SendAsync(Preflight(origin), ct);

        // Sans cet en-tête, le navigateur bloque la vraie requête.
        Assert.Null(AllowOrigin(response));
    }

    [Fact]
    public async Task HorsDevelopment_MemeLocalhost_SansEnTeteCors()
    {
        var ct = TestContext.Current.CancellationToken;
        // La factory de base tourne en « Testing », comme une production
        // du point de vue de CORS : UseCors n'est pas appelé.
        using var client = factory.CreateClient();

        using var response = await client.SendAsync(Preflight(FlutterWebOrigin), ct);

        Assert.Null(AllowOrigin(response));
    }

    [Fact]
    public async Task Development_Reponse429_GardeLEnTeteCors()
    {
        var ct = TestContext.Current.CancellationToken;
        // Limite à 1 essai : le deuxième appel reçoit 429.
        using var devFactory = CreateFactory("Development", permitLimit: "1");
        using var client = devFactory.CreateClient();

        using var first = await client.SendAsync(LoginRequest(FlutterWebOrigin), ct);
        using var second = await client.SendAsync(LoginRequest(FlutterWebOrigin), ct);

        Assert.Equal(HttpStatusCode.Unauthorized, first.StatusCode);
        Assert.Equal(HttpStatusCode.TooManyRequests, second.StatusCode);
        // Vérifie l'ordre dans Program.cs : CORS avant la limite d'essais.
        // Sans cet en-tête, Chrome masquerait le 429 derrière une erreur réseau.
        Assert.Equal(FlutterWebOrigin, AllowOrigin(second));
    }

    // ---- Outils ----

    private WebApplicationFactory<Program> CreateFactory(string environment, string? permitLimit = null) =>
        factory.WithWebHostBuilder(builder =>
        {
            // Appliqué après la factory de base : remplace « Testing ».
            builder.UseEnvironment(environment);

            if (permitLimit is not null)
            {
                builder.ConfigureAppConfiguration((_, config) =>
                    config.AddInMemoryCollection(new Dictionary<string, string?>
                    {
                        ["RateLimiting:Auth:PermitLimit"] = permitLimit,
                    }));
            }
        });

    /// <summary>
    /// Requête préalable envoyée par Chrome avant un POST JSON vers une autre origine.
    /// </summary>
    private static HttpRequestMessage Preflight(string origin)
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/auth/login");
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "content-type");
        return request;
    }

    /// <summary>Connexion avec un compte qui n'existe pas (valeurs d'exemple) : 401 attendu.</summary>
    private static HttpRequestMessage LoginRequest(string origin)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/auth/login")
        {
            Content = JsonContent.Create(new { email = "candidat@exemple.com", password = "Exemple-Cors-1" }),
        };
        request.Headers.Add("Origin", origin);
        return request;
    }

    private static string? AllowOrigin(HttpResponseMessage response) =>
        response.Headers.TryGetValues(AllowOriginHeader, out var values) ? values.Single() : null;
}

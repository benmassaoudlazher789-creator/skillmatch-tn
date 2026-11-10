using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using SkillMatch.Api.Auth;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Tests.Auth;

/// <summary>
/// Tests de bout en bout de /auth/register et /auth/login : l'API tourne en
/// mémoire avec SQLite. Toutes les valeurs sont des exemples.
/// </summary>
public sealed class AuthEndpointsTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    private const string NomExemple = "Candidat Exemple";
    private const string MotDePasseExemple = "MotDePasse-Exemple-1";

    // Formes attendues des réponses, écrites ici plutôt que reprises de l'API :
    // un champ renommé par erreur côté API fera échouer le test.
    private sealed record RegisterBody(Guid Id, string FullName, string Email);

    private sealed record LoginBody(string AccessToken, string TokenType, int ExpiresIn);

    // Une adresse différente par test : les tests d'une même classe partagent
    // la base, ils ne doivent pas se gêner.
    private static string NouvelEmail() => $"candidat-{Guid.NewGuid():N}@exemple.tn";

    private static Task<HttpResponseMessage> RegisterAsync(
        HttpClient client, string email, string password, CancellationToken ct) =>
        client.PostAsJsonAsync("/auth/register", new { fullName = NomExemple, email, password }, ct);

    private static Task<HttpResponseMessage> LoginAsync(
        HttpClient client, string email, string password, CancellationToken ct) =>
        client.PostAsJsonAsync("/auth/login", new { email, password }, ct);

    [Fact]
    public async Task Register_Valide_Retourne201EtStockeUnHash()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var email = NouvelEmail();

        // Majuscules et espaces : l'adresse doit être enregistrée normalisée.
        using var response = await RegisterAsync(client, $"  {email.ToUpperInvariant()} ", MotDePasseExemple, ct);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync(ct);
        // Choix validé : pas de jeton à l'inscription.
        Assert.DoesNotContain("accessToken", raw, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain(MotDePasseExemple, raw);

        var body = JsonSerializer.Deserialize<RegisterBody>(raw, JsonSerializerOptions.Web);
        Assert.NotNull(body);
        Assert.Equal(email, body.Email);
        Assert.Equal(NomExemple, body.FullName);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SkillMatchDbContext>();
        var user = await db.Users.SingleAsync(u => u.Email == email, ct);
        // « $2 » : préfixe d'un hash BCrypt. Le mot de passe n'est jamais stocké tel quel.
        Assert.StartsWith("$2", user.PasswordHash);
        Assert.DoesNotContain(MotDePasseExemple, user.PasswordHash);
    }

    [Fact]
    public async Task Register_EmailEnDouble_Retourne409()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var email = NouvelEmail();

        using var first = await RegisterAsync(client, email, MotDePasseExemple, ct);
        Assert.Equal(HttpStatusCode.Created, first.StatusCode);

        // Même adresse en majuscules : c'est le même compte après normalisation.
        using var second = await RegisterAsync(client, email.ToUpperInvariant(), MotDePasseExemple, ct);
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Theory]
    [InlineData("pas-une-adresse", "MotDePasse-Exemple-1")]
    [InlineData("candidat@exemple.tn", "court")]
    public async Task Register_ChampsInvalides_Retourne400SansRenvoyerLeMotDePasse(string email, string password)
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await RegisterAsync(client, email, password, ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync(ct);
        Assert.DoesNotContain(password, raw);
    }

    [Fact]
    public async Task Login_MauvaisMotDePasseOuEmailInconnu_MemeReponse401()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var email = NouvelEmail();
        using var registered = await RegisterAsync(client, email, MotDePasseExemple, ct);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);

        using var wrongPassword = await LoginAsync(client, email, "Mauvais-Exemple-2", ct);
        using var unknownEmail = await LoginAsync(client, NouvelEmail(), MotDePasseExemple, ct);

        Assert.Equal(HttpStatusCode.Unauthorized, wrongPassword.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, unknownEmail.StatusCode);
        // Corps identiques : la réponse ne dit pas si l'adresse a un compte.
        Assert.Equal(
            await wrongPassword.Content.ReadAsStringAsync(ct),
            await unknownEmail.Content.ReadAsStringAsync(ct));
    }

    [Fact]
    public async Task Login_Valide_RetourneUnJetonValide()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var email = NouvelEmail();
        using var registered = await RegisterAsync(client, email, MotDePasseExemple, ct);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);

        // Majuscules à la connexion : la recherche utilise la même normalisation.
        using var response = await LoginAsync(client, email.ToUpperInvariant(), MotDePasseExemple, ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<LoginBody>(ct);
        Assert.NotNull(body);
        Assert.Equal("Bearer", body.TokenType);

        var jwtOptions = factory.Services.GetRequiredService<IOptions<JwtOptions>>().Value;
        Assert.Equal(jwtOptions.LifetimeMinutes * 60, body.ExpiresIn);

        // Signature, émetteur, destinataire et expiration contrôlés avec les règles de l'API.
        var result = await new JsonWebTokenHandler().ValidateTokenAsync(
            body.AccessToken, TokenService.CreateValidationParameters(jwtOptions));
        Assert.True(result.IsValid, result.Exception?.Message);

        var token = Assert.IsType<JsonWebToken>(result.SecurityToken);
        Assert.Equal("HS256", token.Alg);
        Assert.Equal(jwtOptions.Issuer, token.Issuer);
        Assert.Contains(jwtOptions.Audience, token.Audiences);
        Assert.Equal(TimeSpan.FromMinutes(jwtOptions.LifetimeMinutes), token.ValidTo - token.IssuedAt);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SkillMatchDbContext>();
        var user = await db.Users.SingleAsync(u => u.Email == email, ct);
        Assert.Equal(user.Id.ToString(), token.Subject);

        // Aucune donnée personnelle dans le jeton, lisible par quiconque le détient.
        Assert.False(token.TryGetPayloadValue<string>("email", out _));
    }

    [Fact]
    public async Task Auth_SixiemeEssaiDansLaMinute_Retourne429()
    {
        var ct = TestContext.Current.CancellationToken;

        // Copie de l'API avec la vraie limite de production. Nouvelle API, donc
        // nouveaux compteurs : les autres tests ne sont pas touchés.
        using var limitedFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, config) =>
                config.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["RateLimiting:Auth:PermitLimit"] =
                        AuthRateLimitOptions.DefaultPermitLimit.ToString(System.Globalization.CultureInfo.InvariantCulture),
                })));
        using var client = limitedFactory.CreateClient();

        for (var essai = 1; essai <= AuthRateLimitOptions.DefaultPermitLimit; essai++)
        {
            using var accepted = await LoginAsync(client, NouvelEmail(), MotDePasseExemple, ct);
            Assert.Equal(HttpStatusCode.Unauthorized, accepted.StatusCode);
        }

        using var rejected = await LoginAsync(client, NouvelEmail(), MotDePasseExemple, ct);
        Assert.Equal(HttpStatusCode.TooManyRequests, rejected.StatusCode);
    }

    [Theory]
    [InlineData("")]
    [InlineData("cle-trop-courte")]
    public void Demarrage_SansCleJwtValable_Echoue(string signingKey)
    {
        using var factoryWithoutKey = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, config) =>
                config.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["Jwt:SigningKey"] = signingKey,
                })));

        // CreateClient démarre l'API : ValidateOnStart doit l'arrêter net.
        var exception = Assert.ThrowsAny<Exception>(() => factoryWithoutKey.CreateClient());
        Assert.Contains("Jwt:SigningKey", exception.ToString());
    }
}

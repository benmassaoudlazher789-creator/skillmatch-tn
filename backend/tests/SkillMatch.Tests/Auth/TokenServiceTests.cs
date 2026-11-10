using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using SkillMatch.Api.Auth;
using SkillMatch.Core.Users;

namespace SkillMatch.Tests.Auth;

/// <summary>
/// Cas où un jeton doit être refusé. Tests unitaires : ni serveur ni base.
/// </summary>
public sealed class TokenServiceTests
{
    private static readonly User UtilisateurExemple =
        User.Create("Candidat Exemple", "candidat@exemple.tn", "hash-exemple");

    // Clé aléatoire générée à l'exécution : rien n'est écrit dans le dépôt.
    private static JwtOptions OptionsExemple() => new()
    {
        SigningKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
    };

    // Horloge figée : permet de fabriquer un jeton émis dans le passé.
    private sealed class HorlogeFixe(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
    }

    [Fact]
    public async Task Jeton_Expire_EstRefuse()
    {
        var options = OptionsExemple();
        var service = new TokenService(Options.Create(options), new HorlogeFixe(DateTimeOffset.UtcNow.AddHours(-2)));

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(
            service.CreateToken(UtilisateurExemple), TokenService.CreateValidationParameters(options));

        Assert.False(result.IsValid);
        Assert.IsType<SecurityTokenExpiredException>(result.Exception);
    }

    [Fact]
    public async Task Jeton_SigneAvecUneAutreCle_EstRefuse()
    {
        var service = new TokenService(Options.Create(OptionsExemple()), TimeProvider.System);

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(
            service.CreateToken(UtilisateurExemple), TokenService.CreateValidationParameters(OptionsExemple()));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task Jeton_SansSignature_EstRefuse()
    {
        var options = OptionsExemple();

        // Pas de SigningCredentials : l'en-tête annonce « alg: none ».
        var unsignedToken = new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = options.Issuer,
            Audience = options.Audience,
            Expires = DateTime.UtcNow.AddMinutes(5),
            Claims = new Dictionary<string, object>
            {
                [JwtRegisteredClaimNames.Sub] = UtilisateurExemple.Id.ToString(),
            },
        });

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(
            unsignedToken, TokenService.CreateValidationParameters(options));

        Assert.False(result.IsValid);
    }
}

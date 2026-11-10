using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using SkillMatch.Core.Users;

namespace SkillMatch.Api.Auth;

/// <summary>
/// Fabrique les jetons JWT et fournit les règles pour les contrôler.
/// Création et contrôle partagent la même clé et les mêmes règles, définies ici.
/// </summary>
public sealed class TokenService
{
    private readonly JwtOptions _options;

    // TimeProvider plutôt que DateTimeOffset.UtcNow : un test peut fixer
    // l'heure et fabriquer un jeton déjà expiré.
    private readonly TimeProvider _timeProvider;

    private readonly JsonWebTokenHandler _handler = new();

    public TokenService(IOptions<JwtOptions> options, TimeProvider timeProvider)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentNullException.ThrowIfNull(timeProvider);

        _options = options.Value;
        _timeProvider = timeProvider;
    }

    /// <summary>Durée de vie en secondes, renvoyée à l'application dans « expiresIn ».</summary>
    public int LifetimeSeconds => _options.LifetimeMinutes * 60;

    public string CreateToken(User user)
    {
        ArgumentNullException.ThrowIfNull(user);

        var now = _timeProvider.GetUtcNow();
        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = _options.Issuer,
            Audience = _options.Audience,
            IssuedAt = now.UtcDateTime,
            NotBefore = now.UtcDateTime,
            Expires = now.AddMinutes(_options.LifetimeMinutes).UtcDateTime,
            // Seulement des identifiants : n'importe qui peut lire le contenu d'un
            // JWT (il est signé, pas caché). Donc ni e-mail, ni nom, ni rôle sensible.
            Claims = new Dictionary<string, object>
            {
                [JwtRegisteredClaimNames.Sub] = user.Id.ToString(),
                // Identifiant unique du jeton : servira si l'on veut un jour en révoquer un.
                [JwtRegisteredClaimNames.Jti] = Guid.NewGuid().ToString(),
            },
            SigningCredentials = new SigningCredentials(CreateSigningKey(_options), SecurityAlgorithms.HmacSha256),
        };

        return _handler.CreateToken(descriptor);
    }

    public static SymmetricSecurityKey CreateSigningKey(JwtOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);
        return new SymmetricSecurityKey(Encoding.UTF8.GetBytes(options.SigningKey));
    }

    /// <summary>
    /// Règles de contrôle d'un jeton reçu, utilisées par l'authentification JwtBearer
    /// et par les tests (mêmes règles des deux côtés).
    /// </summary>
    public static TokenValidationParameters CreateValidationParameters(JwtOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);

        return new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = options.Issuer,
            ValidateAudience = true,
            ValidAudience = options.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = CreateSigningKey(options),
            // Liste fermée d'algorithmes : un jeton « alg: none » ou signé
            // autrement est refusé, quoi que dise son en-tête.
            ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
            RequireSignedTokens = true,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            // Tolérance de 30 s pour les horloges un peu décalées
            // (5 min par défaut, ce qui allongerait la vie du jeton).
            ClockSkew = TimeSpan.FromSeconds(30),
        };
    }
}

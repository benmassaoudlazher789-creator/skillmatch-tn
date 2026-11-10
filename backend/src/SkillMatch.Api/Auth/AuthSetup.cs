using System.Globalization;
using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Options;

namespace SkillMatch.Api.Auth;

/// <summary>
/// Enregistre tout ce qui concerne les comptes côté API : options JWT,
/// fabrique de jetons, authentification JwtBearer et limite d'essais.
/// Program.cs reste ainsi court et lisible.
/// </summary>
public static class AuthSetup
{
    public const string TooManyAttemptsMessage = "Trop de tentatives. Réessayez dans une minute.";

    public static IServiceCollection AddApiAuth(this IServiceCollection services)
    {
        // ValidateOnStart : l'API refuse de démarrer si la clé manque ou est trop
        // courte. Mieux vaut une erreur immédiate qu'une API qui signe avec une
        // clé faible. Le contrôle a lieu au démarrage, pas à la construction :
        // les commandes « dotnet ef » ne sont donc pas bloquées.
        services.AddOptions<JwtOptions>()
            .BindConfiguration(JwtOptions.SectionName)
            .Validate(
                o => !string.IsNullOrEmpty(o.SigningKey)
                    && Encoding.UTF8.GetByteCount(o.SigningKey) >= JwtOptions.MinSigningKeyBytes,
                $"La clé 'Jwt:SigningKey' est absente ou trop courte ({JwtOptions.MinSigningKeyBytes} octets au moins). " +
                "Configurez-la avec dotnet user-secrets (voir backend/README.md).")
            .Validate(
                o => !string.IsNullOrWhiteSpace(o.Issuer) && !string.IsNullOrWhiteSpace(o.Audience),
                "'Jwt:Issuer' et 'Jwt:Audience' sont obligatoires (voir appsettings.json).")
            .Validate(
                o => o.LifetimeMinutes is >= 1 and <= 60,
                "'Jwt:LifetimeMinutes' doit être entre 1 et 60 : un jeton doit rester de courte durée.")
            .ValidateOnStart();

        services.AddOptions<AuthRateLimitOptions>()
            .BindConfiguration(AuthRateLimitOptions.SectionName)
            .Validate(
                o => o.PermitLimit > 0,
                "'RateLimiting:Auth:PermitLimit' doit être supérieur à 0.")
            .ValidateOnStart();

        // TryAdd : un test pourrait fournir sa propre horloge avant cet appel.
        services.TryAddSingleton(TimeProvider.System);
        services.AddSingleton<TokenService>();

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();

        // Les règles JwtBearer sont construites à partir de JwtOptions au moment
        // où elles servent, avec les mêmes paramètres que les tests.
        services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<JwtOptions>>((bearer, jwt) =>
            {
                // Garde « sub » tel quel, sans le renommer en un long nom de claim .NET.
                bearer.MapInboundClaims = false;
                bearer.TokenValidationParameters = TokenService.CreateValidationParameters(jwt.Value);
            });

        services.AddAuthorization();

        services.AddRateLimiter(options =>
        {
            // 429 Too Many Requests (par défaut ce serait 503, qui ferait croire à une panne).
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.OnRejected = (context, cancellationToken) =>
            {
                var response = context.HttpContext.Response;
                response.Headers.RetryAfter =
                    ((int)AuthRateLimitOptions.Window.TotalSeconds).ToString(CultureInfo.InvariantCulture);
                return new ValueTask(
                    response.WriteAsJsonAsync(new ErrorResponse(TooManyAttemptsMessage), cancellationToken));
            };

            // Fenêtre fixe, un compteur par adresse IP. La limite est lue dans
            // les options à chaque requête, pour que les tests puissent la régler.
            options.AddPolicy(AuthEndpoints.RateLimitPolicy, httpContext =>
            {
                var permitLimit = httpContext.RequestServices
                    .GetRequiredService<IOptions<AuthRateLimitOptions>>().Value.PermitLimit;

                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "ip-inconnue",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = permitLimit,
                        Window = AuthRateLimitOptions.Window,
                        // Aucune file d'attente : au-delà de la limite, refus immédiat.
                        QueueLimit = 0,
                    });
            });
        });

        return services;
    }
}

using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;

namespace SkillMatch.Api.Cv;

/// <summary>
/// Enregistre ce qui concerne l'analyse des CV côté API : options et limite
/// d'analyses. Le travail lui-même (CvAnalyzer, CvTextExtractor) est
/// enregistré par AddInfrastructure.
/// </summary>
public static class CvSetup
{
    public static IServiceCollection AddCvAnalysis(this IServiceCollection services)
    {
        services.AddOptions<CvRateLimitOptions>()
            .BindConfiguration(CvRateLimitOptions.SectionName)
            .Validate(
                o => o.PermitLimit > 0,
                "'RateLimiting:Cv:PermitLimit' doit être supérieur à 0.")
            .ValidateOnStart();

        // Ajoute une politique aux options du limiteur déjà créé par AddApiAuth
        // (même code 429 et même message pour toutes les politiques).
        services.Configure<RateLimiterOptions>(options =>
            options.AddPolicy(CvEndpoints.RateLimitPolicy, httpContext =>
            {
                var permitLimit = httpContext.RequestServices
                    .GetRequiredService<IOptions<CvRateLimitOptions>>().Value.PermitLimit;

                // Un compteur par COMPTE (l'Id « sub » du jeton), pas par adresse
                // IP : plusieurs étudiants derrière le Wi-Fi d'une école ont la
                // même IP. La route exige un jeton, donc « sub » est toujours là ;
                // l'IP n'est qu'une solution de secours.
                var partitionKey = httpContext.User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                    ?? httpContext.Connection.RemoteIpAddress?.ToString()
                    ?? "inconnu";

                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey,
                    _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = permitLimit,
                        Window = CvRateLimitOptions.Window,
                        QueueLimit = 0,
                    });
            }));

        return services;
    }
}

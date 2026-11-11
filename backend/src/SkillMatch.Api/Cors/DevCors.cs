using Microsoft.Net.Http.Headers;

namespace SkillMatch.Api.Cors;

/// <summary>
/// CORS pour le développement seulement.
///
/// Pourquoi ? Avec « flutter run -d chrome », l'application tourne sur
/// http://localhost:&lt;port&gt; et l'API sur http://localhost:5080. Le port
/// diffère, donc pour Chrome ce sont deux « origines » différentes : sans
/// en-tête CORS, il bloque la réponse. Une application Android ou iOS n'est
/// pas un navigateur et n'est pas concernée.
///
/// La politique est toujours enregistrée, mais Program.cs ne l'active
/// (UseCors) qu'en environnement Development : en production, aucune
/// origine extérieure n'est acceptée.
/// </summary>
public static class DevCors
{
    public const string PolicyName = "DevLocalhost";

    public static IServiceCollection AddDevCors(this IServiceCollection services)
    {
        services.AddCors(options => options.AddPolicy(PolicyName, policy => policy
            // Flutter choisit un port au hasard à chaque lancement : on ne peut
            // pas lister des origines fixes, on vérifie donc l'hôte.
            .SetIsOriginAllowed(IsLocalhostOrigin)
            // Juste ce qu'il faut : POST pour /auth/* et /cv, Content-Type pour
            // le JSON et le formulaire, Authorization pour le jeton envoyé à /cv.
            // On ajoutera GET quand une route en aura besoin.
            .WithMethods(HttpMethods.Post)
            .WithHeaders(HeaderNames.ContentType, HeaderNames.Authorization)));
        // Pas d'AllowCredentials : le jeton voyage dans un en-tête, pas dans
        // un cookie, donc le navigateur n'a pas à envoyer de cookies.

        return services;
    }

    /// <summary>
    /// Vrai seulement pour http(s)://localhost:&lt;port&gt; ou http(s)://127.0.0.1:&lt;port&gt;.
    /// On analyse l'adresse avec Uri au lieu de tester le début du texte :
    /// un simple StartsWith("http://localhost") laisserait passer
    /// « http://localhost.exemple.com ».
    /// </summary>
    public static bool IsLocalhostOrigin(string origin) =>
        Uri.TryCreate(origin, UriKind.Absolute, out var uri)
        && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)
        && (uri.Host == "localhost" || uri.Host == "127.0.0.1");
}

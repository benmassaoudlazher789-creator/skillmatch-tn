using Microsoft.AspNetCore.RateLimiting;
using SkillMatch.Infrastructure.Auth;

namespace SkillMatch.Api.Auth;

/// <summary>
/// Routes POST /auth/register et POST /auth/login.
/// Elles contrôlent les champs, appellent AuthService, puis traduisent
/// le résultat en code HTTP. La logique métier reste dans AuthService.
/// </summary>
public static class AuthEndpoints
{
    /// <summary>Nom de la politique de limite d'essais (voir AuthSetup).</summary>
    public const string RateLimitPolicy = "auth";

    /// <summary>
    /// Même message pour un e-mail inconnu et un mauvais mot de passe :
    /// la réponse ne dit pas lequel des deux est faux.
    /// </summary>
    public const string InvalidCredentialsMessage = "E-mail ou mot de passe incorrect.";

    public const string EmailAlreadyUsedMessage = "Un compte existe déjà avec cette adresse.";

    private const string LoggerCategory = "SkillMatch.Api.Auth";

    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        // La limite d'essais s'applique au groupe entier : inscription et
        // connexion partagent le même compteur par adresse IP.
        var group = app.MapGroup("/auth").RequireRateLimiting(RateLimitPolicy);

        group.MapPost("/register", RegisterAsync);
        group.MapPost("/login", LoginAsync);

        return app;
    }

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        AuthService authService,
        ILoggerFactory loggerFactory,
        HttpContext httpContext,
        CancellationToken cancellationToken)
    {
        var errors = AuthValidation.ValidateRegister(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var logger = loggerFactory.CreateLogger(LoggerCategory);
        var remoteIp = httpContext.Connection.RemoteIpAddress;

        // Les « ! » sont sûrs : ValidateRegister vient de refuser les champs vides.
        var user = await authService.RegisterAsync(
            request.FullName!, request.Email!, request.Password!, cancellationToken);

        // Journal d'audit : l'événement, l'Id et l'IP seulement. Jamais le corps
        // de la requête, donc jamais le mot de passe.
        if (user is null)
        {
            logger.LogInformation("Inscription refusée (adresse déjà utilisée) depuis {RemoteIp}.", remoteIp);
            return Results.Conflict(new ErrorResponse(EmailAlreadyUsedMessage));
        }

        logger.LogInformation("Inscription : compte {UserId} créé depuis {RemoteIp}.", user.Id, remoteIp);

        // 201 sans jeton : l'application appelle ensuite /auth/login (choix validé).
        return Results.Json(
            new RegisterResponse(user.Id, user.FullName, user.Email),
            statusCode: StatusCodes.Status201Created);
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        AuthService authService,
        TokenService tokenService,
        ILoggerFactory loggerFactory,
        HttpContext httpContext,
        CancellationToken cancellationToken)
    {
        var errors = AuthValidation.ValidateLogin(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var logger = loggerFactory.CreateLogger(LoggerCategory);
        var remoteIp = httpContext.Connection.RemoteIpAddress;

        // Les « ! » sont sûrs : ValidateLogin vient de refuser les champs vides.
        var user = await authService.LoginAsync(request.Email!, request.Password!, cancellationToken);

        if (user is null)
        {
            // Pas d'e-mail dans ce log : l'IP suffit pour repérer une série d'essais.
            logger.LogWarning("Connexion refusée depuis {RemoteIp}.", remoteIp);
            return Results.Json(
                new ErrorResponse(InvalidCredentialsMessage),
                statusCode: StatusCodes.Status401Unauthorized);
        }

        logger.LogInformation("Connexion du compte {UserId} depuis {RemoteIp}.", user.Id, remoteIp);

        return Results.Ok(new LoginResponse(
            tokenService.CreateToken(user),
            "Bearer",
            tokenService.LifetimeSeconds));
    }
}

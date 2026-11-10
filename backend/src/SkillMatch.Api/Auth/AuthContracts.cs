namespace SkillMatch.Api.Auth;

// Corps JSON échangés avec l'application mobile.
// Champs des requêtes nullables : un champ absent du JSON arrive à null, et la
// validation renvoie alors un message clair au lieu d'une erreur obscure.

/// <summary>Corps de POST /auth/register.</summary>
public sealed record RegisterRequest(string? FullName, string? Email, string? Password)
{
    // Le ToString généré par un record afficherait le mot de passe. On le
    // remplace pour qu'un log écrit par erreur ne le contienne jamais.
    public override string ToString() => $"RegisterRequest {{ Email = {Email} }}";
}

/// <summary>Corps de POST /auth/login.</summary>
public sealed record LoginRequest(string? Email, string? Password)
{
    // Même raison que pour RegisterRequest : jamais de mot de passe dans un log.
    public override string ToString() => $"LoginRequest {{ Email = {Email} }}";
}

/// <summary>Réponse 201 de l'inscription : pas de jeton, l'application appelle ensuite /auth/login.</summary>
public sealed record RegisterResponse(Guid Id, string FullName, string Email);

/// <summary>Réponse 200 de la connexion. ExpiresIn est en secondes.</summary>
public sealed record LoginResponse(string AccessToken, string TokenType, int ExpiresIn);

/// <summary>Erreur simple (401, 409, 429) avec un message en français.</summary>
public sealed record ErrorResponse(string Title);

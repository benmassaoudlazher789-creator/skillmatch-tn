using SkillMatch.Api.Auth;
using SkillMatch.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// En environnement Development, CreateBuilder charge aussi les user-secrets :
// c'est là que se trouvent ConnectionStrings:SkillMatch et Jwt:SigningKey,
// jamais dans le dépôt.
builder.Services.AddInfrastructure(builder.Configuration);

// Jetons JWT, authentification et limite d'essais (voir Auth/AuthSetup.cs).
// Volontairement, pas d'AddHttpLogging : il peut écrire le corps des
// requêtes dans les logs, donc des mots de passe.
builder.Services.AddApiAuth();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

// Sonde de vivacité : répond « le processus tourne-t-il ? ».
// Elle ne touche pas la base, pour qu'une base momentanément arrêtée
// ne fasse pas croire que l'API est tombée (un /health/db viendra plus tard).
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapAuthEndpoints();

app.Run();

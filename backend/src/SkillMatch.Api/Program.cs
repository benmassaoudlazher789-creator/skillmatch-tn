using SkillMatch.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// En environnement Development, CreateBuilder charge aussi les user-secrets :
// c'est là que se trouve ConnectionStrings:SkillMatch, jamais dans le dépôt.
builder.Services.AddInfrastructure(builder.Configuration);

var app = builder.Build();

// Sonde de vivacité : répond « le processus tourne-t-il ? ».
// Elle ne touche pas la base, pour qu'une base momentanément arrêtée
// ne fasse pas croire que l'API est tombée (un /health/db viendra plus tard).
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();

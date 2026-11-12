using SkillMatch.Api.Auth;
using SkillMatch.Api.Cors;
using SkillMatch.Api.Cv;
using SkillMatch.Api.Offers;
using SkillMatch.Api.Trainings;
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

// Analyse des CV : limite d'analyses par compte (voir Cv/CvSetup.cs).
builder.Services.AddCvAnalysis();

// Offres : import des exemples au démarrage, en développement seulement
// (voir Offers/OffersSetup.cs).
builder.Services.AddOffers(builder.Environment);

// Formations : même principe que les offres (voir Trainings/TrainingsSetup.cs).
builder.Services.AddTrainings(builder.Environment);

// Autorise l'application Flutter lancée dans Chrome (voir Cors/DevCors.cs).
builder.Services.AddDevCors();

var app = builder.Build();

// CORS seulement en développement, et EN PREMIER : placé avant la limite
// d'essais, il ajoute aussi son en-tête aux réponses 429. Sinon Chrome
// bloquerait ces réponses et l'application croirait à une panne réseau au
// lieu d'afficher « Trop de tentatives ». Il répond aussi lui-même aux
// requêtes préalables OPTIONS, qui ne consomment donc pas d'essai.
if (app.Environment.IsDevelopment())
{
    app.UseCors(DevCors.PolicyName);
}

app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

// Sonde de vivacité : répond « le processus tourne-t-il ? ».
// Elle ne touche pas la base, pour qu'une base momentanément arrêtée
// ne fasse pas croire que l'API est tombée (un /health/db viendra plus tard).
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapAuthEndpoints();
app.MapCvEndpoints();
app.MapOffersEndpoints();
app.MapTrainingsEndpoints();

app.Run();

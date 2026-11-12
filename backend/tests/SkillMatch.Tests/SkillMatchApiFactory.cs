using System.Security.Cryptography;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Tests;

/// <summary>
/// Démarre l'API en mémoire pour les tests, avec une base SQLite en mémoire
/// à la place de PostgreSQL.
/// </summary>
public sealed class SkillMatchApiFactory : WebApplicationFactory<Program>
{
    /// <summary>
    /// Limite d'essais relevée pour les tests ordinaires : elle reste active,
    /// mais une classe de tests qui envoie une dizaine de requêtes ne la touche pas.
    /// Le test du 429 remet la vraie valeur (5) sur une copie de l'API.
    /// </summary>
    public const string TestAuthPermitLimit = "100";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Environnement « Testing » et non « Development » : les user-secrets
        // de votre machine ne sont pas chargés, donc les tests donnent le même
        // résultat partout et n'ont jamais besoin de PostgreSQL.
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                // Clé tirée au hasard à chaque démarrage : aucune clé n'est
                // écrite dans un fichier, et elle change à chaque exécution.
                ["Jwt:SigningKey"] = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                // Facteur BCrypt minimal : un hash en quelques millisecondes,
                // au lieu d'environ 250 ms avec le facteur 12 de production.
                ["PasswordHashing:WorkFactor"] = "4",
                ["RateLimiting:Auth:PermitLimit"] = TestAuthPermitLimit,
                // Pas d'import des offres d'exemple au démarrage, même pour les
                // copies de l'API en « Development » (tests CORS) : l'API démarre
                // AVANT que CreateHost crée les tables. Les tests des offres
                // importent eux-mêmes ce dont ils ont besoin.
                ["Jobs:ImportSampleOnStartup"] = "false",
                // Même raison pour les formations d'exemple.
                ["Trainings:ImportSampleOnStartup"] = "false",
            });
        });

        builder.ConfigureTestServices(services =>
        {
            // On retire la configuration Npgsql d'AddInfrastructure. Depuis EF Core 9,
            // elle est enregistrée comme IDbContextOptionsConfiguration : retirer
            // seulement DbContextOptions ne suffirait pas.
            services.RemoveAll<DbContextOptions<SkillMatchDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<SkillMatchDbContext>>();

            // Une base SQLite « :memory: » disparaît dès que sa connexion se ferme.
            // On garde donc une seule connexion ouverte pendant toute la vie de
            // l'API de test (singleton, fermée quand la factory est libérée).
            services.AddSingleton(_ =>
            {
                var connection = new SqliteConnection("DataSource=:memory:");
                connection.Open();
                return connection;
            });

            services.AddDbContext<SkillMatchDbContext>((serviceProvider, options) =>
                options.UseSqlite(serviceProvider.GetRequiredService<SqliteConnection>()));
        });
    }

    protected override IHost CreateHost(IHostBuilder builder)
    {
        var host = base.CreateHost(builder);

        // EnsureCreated crée la table users et l'index unique à partir du
        // modèle EF Core (UserConfiguration), sans passer par les migrations,
        // qui sont écrites pour PostgreSQL.
        using var scope = host.Services.CreateScope();
        scope.ServiceProvider.GetRequiredService<SkillMatchDbContext>().Database.EnsureCreated();

        return host;
    }
}

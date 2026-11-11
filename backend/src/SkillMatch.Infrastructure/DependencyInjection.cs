using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SkillMatch.Core.Cv;
using SkillMatch.Core.Users;
using SkillMatch.Infrastructure.Auth;
using SkillMatch.Infrastructure.Cv;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure;

/// <summary>
/// Enregistre les services de l'infrastructure. Program.cs n'a ainsi
/// qu'une ligne à appeler et ne connaît pas les détails d'EF Core.
/// </summary>
public static class DependencyInjection
{
    /// <summary>Nom de la clé, jamais sa valeur : la valeur vit dans user-secrets.</summary>
    public const string ConnectionStringName = "SkillMatch";

    /// <summary>Facteur BCrypt : 12 en production (appsettings.json), 4 dans les tests pour aller vite.</summary>
    public const string PasswordWorkFactorKey = "PasswordHashing:WorkFactor";

    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // La chaîne est lue et contrôlée DANS ce lambda, qui ne s'exécute qu'à
        // la première création du DbContext. Pourquoi : /health et les tests
        // n'utilisent pas la base, ils doivent donc démarrer même sans chaîne.
        // Un vrai endpoint qui utilise la base, lui, échoue avec un message clair.
        services.AddDbContext<SkillMatchDbContext>(options =>
        {
            var connectionString = configuration.GetConnectionString(ConnectionStringName);
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException(
                    $"Chaîne de connexion 'ConnectionStrings:{ConnectionStringName}' absente. " +
                    "Configurez-la avec dotnet user-secrets (voir backend/README.md).");
            }

            options.UseNpgsql(connectionString);
        });

        // Singleton : le hasher ne garde aucun état propre à une requête.
        // La configuration est lue dans le lambda, donc au premier usage :
        // les valeurs ajoutées par les tests sont déjà en place à ce moment-là.
        services.AddSingleton<IPasswordHasher>(serviceProvider =>
        {
            var value = serviceProvider.GetRequiredService<IConfiguration>()[PasswordWorkFactorKey];
            return new BcryptPasswordHasher(ParseWorkFactor(value));
        });

        // Scoped, comme le DbContext qu'il utilise : un par requête HTTP.
        services.AddScoped<AuthService>();

        // Analyse des CV. Singletons : ni l'un ni l'autre ne garde d'état
        // entre deux appels (et aucun CV n'est conservé, voir CvAnalyzer).
        services.AddSingleton<ICvTextExtractor, CvTextExtractor>();
        services.AddSingleton<CvAnalyzer>();

        return services;
    }

    private static int ParseWorkFactor(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return BcryptPasswordHasher.DefaultWorkFactor;
        }

        if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var workFactor)
            && workFactor >= BcryptPasswordHasher.MinWorkFactor
            && workFactor <= BcryptPasswordHasher.MaxWorkFactor)
        {
            return workFactor;
        }

        throw new InvalidOperationException(
            $"'{PasswordWorkFactorKey}' doit être un entier entre {BcryptPasswordHasher.MinWorkFactor} " +
            $"et {BcryptPasswordHasher.MaxWorkFactor} (valeur actuelle : « {value} »).");
    }
}

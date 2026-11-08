using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
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

        return services;
    }
}

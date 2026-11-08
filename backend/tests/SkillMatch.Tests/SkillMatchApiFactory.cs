using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace SkillMatch.Tests;

/// <summary>
/// Démarre l'API en mémoire pour les tests.
/// </summary>
public sealed class SkillMatchApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Environnement « Testing » et non « Development » : les user-secrets
        // de votre machine ne sont pas chargés, donc les tests donnent le même
        // résultat partout et n'ont jamais besoin de PostgreSQL.
        builder.UseEnvironment("Testing");
    }
}

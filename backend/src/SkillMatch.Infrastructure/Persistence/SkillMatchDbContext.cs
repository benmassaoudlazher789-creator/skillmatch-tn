using Microsoft.EntityFrameworkCore;
using SkillMatch.Core.Users;

namespace SkillMatch.Infrastructure.Persistence;

/// <summary>
/// Point d'entrée d'EF Core vers la base « skillmatch ».
/// Chaque nouvelle table s'ajoute par un DbSet, une configuration dans
/// Persistence/Configurations, puis une migration.
/// </summary>
public sealed class SkillMatchDbContext(DbContextOptions<SkillMatchDbContext> options)
    : DbContext(options)
{
    // Propriété calculée plutôt qu'un setter auto : évite l'avertissement
    // nullable CS8618, bloquant ici à cause de TreatWarningsAsErrors.
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Charge toutes les classes IEntityTypeConfiguration du projet :
        // une nouvelle configuration est prise en compte sans toucher ce fichier.
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SkillMatchDbContext).Assembly);
    }
}

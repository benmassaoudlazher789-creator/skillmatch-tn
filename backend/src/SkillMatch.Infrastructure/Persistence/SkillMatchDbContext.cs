using Microsoft.EntityFrameworkCore;

namespace SkillMatch.Infrastructure.Persistence;

/// <summary>
/// Point d'entrée d'EF Core vers la base « skillmatch ».
/// Aucun DbSet pour l'instant : les tables arriveront avec les premières
/// entités du domaine, chacune via une migration.
/// </summary>
public sealed class SkillMatchDbContext(DbContextOptions<SkillMatchDbContext> options)
    : DbContext(options)
{
}

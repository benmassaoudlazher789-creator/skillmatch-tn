using Microsoft.EntityFrameworkCore;
using SkillMatch.Core.Jobs;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure.Jobs;

/// <summary>
/// Lecture des offres enregistrées, pour la route GET /offers.
///
/// Toutes les offres sont chargées puis notées en mémoire (voir JobRanker) :
/// le score dépend des compétences du candidat, et le calcul en C# reste
/// lisible et testé. C'est largement suffisant pour quelques centaines
/// d'offres ; avec une vraie source plus volumineuse, il faudra d'abord
/// filtrer en SQL (par exemple sur les compétences demandées).
/// </summary>
public sealed class JobCatalog(SkillMatchDbContext db)
{
    public async Task<IReadOnlyList<Job>> ListAsync(CancellationToken cancellationToken) =>
        await db.Jobs
            // Lecture seule : EF Core ne suit pas les objets, c'est plus rapide.
            .AsNoTracking()
            .Include(j => j.Skills)
            .ToListAsync(cancellationToken);
}

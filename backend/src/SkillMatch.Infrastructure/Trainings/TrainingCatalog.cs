using Microsoft.EntityFrameworkCore;
using SkillMatch.Core.Trainings;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure.Trainings;

/// <summary>
/// Lecture des formations enregistrées, pour la route GET /trainings.
///
/// Le filtre se fait en SQL (égalité sur la colonne indexée skill_key) ;
/// seul le tri se fait ensuite en C#, sur les quelques formations d'une
/// compétence (voir <see cref="Training.InDisplayOrder"/>).
/// </summary>
public sealed class TrainingCatalog(SkillMatchDbContext db)
{
    /// <summary>
    /// Formations dont la compétence a la clé <paramref name="skillKey"/>
    /// (calculée par SkillKey.For), dans l'ordre d'affichage.
    /// </summary>
    public async Task<IReadOnlyList<Training>> ForSkillAsync(string skillKey, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(skillKey);

        var found = await db.Trainings
            // Lecture seule : EF Core ne suit pas les objets, c'est plus rapide.
            .AsNoTracking()
            .Where(t => t.SkillKey == skillKey)
            .ToListAsync(cancellationToken);

        return Training.InDisplayOrder(found);
    }
}

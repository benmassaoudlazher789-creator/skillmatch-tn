using Microsoft.EntityFrameworkCore;
using SkillMatch.Core.Jobs;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure.Jobs;

/// <summary>Bilan d'un import : seulement des nombres, jamais le contenu des offres.</summary>
public sealed record JobImportResult(int Added, int Updated, int Rejected);

/// <summary>
/// Copie en base les offres d'une source (<see cref="IJobSource"/>).
///
/// Une offre déjà connue (même source, même identifiant externe) est mise à
/// jour, une nouvelle est ajoutée : lancer l'import deux fois ne crée aucun
/// doublon. Une offre invalide (lien dangereux, compétence en double…) est
/// écartée et comptée, sans bloquer les autres : une vraie source aura
/// forcément quelques annonces mal remplies.
///
/// Limite assumée : une offre retirée par la source reste en base. Il faudra
/// la marquer « expirée » quand une vraie source sera branchée.
/// </summary>
public sealed class JobImporter(SkillMatchDbContext db)
{
    public async Task<JobImportResult> ImportAsync(IJobSource source, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(source);

        var postings = await source.FetchAsync(cancellationToken);

        // Toutes les offres de la source, avec leurs compétences, en une
        // requête : on les retrouve ensuite en mémoire par identifiant.
        var existing = await db.Jobs
            .Include(j => j.Skills)
            .Where(j => j.Source == source.Name)
            .ToDictionaryAsync(j => j.ExternalId, StringComparer.Ordinal, cancellationToken);

        int added = 0, updated = 0, rejected = 0;
        var seen = new HashSet<string>(StringComparer.Ordinal);

        foreach (var posting in postings)
        {
            if (posting is null)
            {
                rejected++;
                continue;
            }

            // Même nettoyage que Job : la clé cherchée est exactement celle
            // qui serait enregistrée.
            var externalId = Job.CleanText(posting.ExternalId);

            // Même identifiant deux fois dans un import : on garde la première.
            if (!seen.Add(externalId))
            {
                rejected++;
                continue;
            }

            try
            {
                if (existing.TryGetValue(externalId, out var job))
                {
                    job.UpdateFrom(posting);
                    updated++;
                }
                else
                {
                    db.Jobs.Add(Job.FromPosting(source.Name, source.IsSample, posting));
                    added++;
                }
            }
            catch (ArgumentException)
            {
                // Le détail (qui peut citer le contenu de l'annonce) n'est pas
                // gardé : le bilan ne contient que des nombres.
                rejected++;
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        return new JobImportResult(added, updated, rejected);
    }
}

using Microsoft.EntityFrameworkCore;
using SkillMatch.Core.Trainings;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure.Trainings;

/// <summary>Bilan d'un import : seulement des nombres, jamais le contenu des formations.</summary>
public sealed record TrainingImportResult(int Added, int Updated, int Rejected);

/// <summary>
/// Copie en base les formations d'une source (<see cref="ITrainingSource"/>).
///
/// Même fonctionnement que JobImporter : une formation déjà connue (même
/// source, même identifiant externe) est mise à jour, une nouvelle est
/// ajoutée, donc lancer l'import deux fois ne crée aucun doublon. Une
/// formation invalide est écartée et comptée, sans bloquer les autres.
///
/// Limite assumée : une formation retirée par la source reste en base.
/// </summary>
public sealed class TrainingImporter(SkillMatchDbContext db)
{
    public async Task<TrainingImportResult> ImportAsync(ITrainingSource source, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(source);

        var postings = await source.FetchAsync(cancellationToken);

        // Toutes les formations de la source en une requête : on les
        // retrouve ensuite en mémoire par identifiant.
        var existing = await db.Trainings
            .Where(t => t.Source == source.Name)
            .ToDictionaryAsync(t => t.ExternalId, StringComparer.Ordinal, cancellationToken);

        int added = 0, updated = 0, rejected = 0;
        var seen = new HashSet<string>(StringComparer.Ordinal);

        foreach (var posting in postings)
        {
            if (posting is null)
            {
                rejected++;
                continue;
            }

            // Même nettoyage que Training : la clé cherchée est exactement
            // celle qui serait enregistrée.
            var externalId = Training.CleanText(posting.ExternalId);

            // Même identifiant deux fois dans un import : on garde la première.
            if (!seen.Add(externalId))
            {
                rejected++;
                continue;
            }

            try
            {
                if (existing.TryGetValue(externalId, out var training))
                {
                    training.UpdateFrom(posting);
                    updated++;
                }
                else
                {
                    db.Trainings.Add(Training.FromPosting(source.Name, source.IsSample, posting));
                    added++;
                }
            }
            catch (ArgumentException)
            {
                // Le détail (qui peut citer le contenu de la formation) n'est
                // pas gardé : le bilan ne contient que des nombres.
                rejected++;
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        return new TrainingImportResult(added, updated, rejected);
    }
}

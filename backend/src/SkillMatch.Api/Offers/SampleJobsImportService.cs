using Microsoft.Extensions.Options;
using SkillMatch.Infrastructure.Jobs;

namespace SkillMatch.Api.Offers;

/// <summary>Réglages des offres, lus dans la section « Jobs ».</summary>
public sealed class JobsOptions
{
    public const string SectionName = "Jobs";

    /// <summary>
    /// Importer les offres d'exemple au démarrage. Faux par défaut ; mis à vrai
    /// par le profil « http » de Properties/launchSettings.json (variable
    /// Jobs__ImportSampleOnStartup, le « __ » remplaçant le « : »), utilisé par
    /// dotnet run. Ignoré hors développement de toute façon (voir OffersSetup).
    /// Pas dans appsettings.Development.json : ce fichier est exclu du dépôt.
    /// </summary>
    public bool ImportSampleOnStartup { get; set; }
}

/// <summary>
/// Au démarrage de l'API en développement, copie les offres d'exemple en base
/// (voir SampleJobSource). Relancer l'API ne crée pas de doublon : l'import
/// met à jour les offres déjà présentes.
///
/// Un échec (base arrêtée, migration AddJobs pas encore appliquée) n'empêche
/// pas l'API de démarrer : il est écrit dans le journal, et GET /offers renverra
/// simplement une erreur tant que la base n'est pas prête.
/// </summary>
public sealed partial class SampleJobsImportService(
    IServiceScopeFactory scopeFactory,
    IOptions<JobsOptions> options,
    ILogger<SampleJobsImportService> logger) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        if (!options.Value.ImportSampleOnStartup)
        {
            return;
        }

        try
        {
            // Le DbContext est « scoped » (un par requête) : un service de
            // démarrage doit donc créer son propre scope pour l'obtenir.
            await using var scope = scopeFactory.CreateAsyncScope();
            var importer = scope.ServiceProvider.GetRequiredService<JobImporter>();
            var source = scope.ServiceProvider.GetRequiredService<SampleJobSource>();

            var result = await importer.ImportAsync(source, cancellationToken);
            LogImported(logger, result.Added, result.Updated, result.Rejected);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Volontairement large : quelle que soit la panne, l'API démarre.
            LogImportFailed(logger, ex);
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    // Messages compilés à l'avance (LoggerMessage) : pas de calcul de texte si
    // le niveau de journal est désactivé. Seulement des nombres, jamais le
    // contenu des offres.
    [LoggerMessage(Level = LogLevel.Information,
        Message = "Offres d'exemple importées : {Added} ajoutées, {Updated} mises à jour, {Rejected} écartées.")]
    private static partial void LogImported(ILogger logger, int added, int updated, int rejected);

    [LoggerMessage(Level = LogLevel.Warning,
        Message = "Import des offres d'exemple impossible. La base est-elle démarrée et la migration AddJobs appliquée (dotnet ef database update) ?")]
    private static partial void LogImportFailed(ILogger logger, Exception exception);
}

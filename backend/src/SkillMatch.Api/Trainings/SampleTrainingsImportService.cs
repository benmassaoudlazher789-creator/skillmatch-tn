using Microsoft.Extensions.Options;
using SkillMatch.Infrastructure.Trainings;

namespace SkillMatch.Api.Trainings;

/// <summary>Réglages des formations, lus dans la section « Trainings ».</summary>
public sealed class TrainingsOptions
{
    public const string SectionName = "Trainings";

    /// <summary>
    /// Importer les formations d'exemple au démarrage. Faux par défaut ; mis à
    /// vrai par le profil « http » de Properties/launchSettings.json (variable
    /// Trainings__ImportSampleOnStartup). Ignoré hors développement de toute
    /// façon (voir TrainingsSetup).
    /// </summary>
    public bool ImportSampleOnStartup { get; set; }
}

/// <summary>
/// Au démarrage de l'API en développement, copie les formations d'exemple en
/// base (voir SampleTrainingSource). Relancer l'API ne crée pas de doublon.
///
/// Comme pour les offres, un échec (base arrêtée, migration AddTrainings pas
/// encore appliquée) n'empêche pas l'API de démarrer : il est écrit dans le
/// journal, et GET /trainings renverra une erreur tant que la base n'est pas
/// prête.
/// </summary>
public sealed partial class SampleTrainingsImportService(
    IServiceScopeFactory scopeFactory,
    IOptions<TrainingsOptions> options,
    ILogger<SampleTrainingsImportService> logger) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        if (!options.Value.ImportSampleOnStartup)
        {
            return;
        }

        try
        {
            // Le DbContext est « scoped » : un service de démarrage crée son propre scope.
            await using var scope = scopeFactory.CreateAsyncScope();
            var importer = scope.ServiceProvider.GetRequiredService<TrainingImporter>();
            var source = scope.ServiceProvider.GetRequiredService<SampleTrainingSource>();

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

    // Seulement des nombres, jamais le contenu des formations.
    [LoggerMessage(Level = LogLevel.Information,
        Message = "Formations d'exemple importées : {Added} ajoutées, {Updated} mises à jour, {Rejected} écartées.")]
    private static partial void LogImported(ILogger logger, int added, int updated, int rejected);

    [LoggerMessage(Level = LogLevel.Warning,
        Message = "Import des formations d'exemple impossible. La base est-elle démarrée et la migration AddTrainings appliquée (dotnet ef database update) ?")]
    private static partial void LogImportFailed(ILogger logger, Exception exception);
}

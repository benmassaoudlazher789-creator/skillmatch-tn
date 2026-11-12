namespace SkillMatch.Api.Trainings;

/// <summary>
/// Enregistre ce qui concerne les formations côté API. La lecture et l'import
/// (TrainingCatalog, TrainingImporter) sont enregistrés par AddInfrastructure.
/// </summary>
public static class TrainingsSetup
{
    public static IServiceCollection AddTrainings(this IServiceCollection services, IHostEnvironment environment)
    {
        ArgumentNullException.ThrowIfNull(environment);

        services.AddOptions<TrainingsOptions>().BindConfiguration(TrainingsOptions.SectionName);

        // Import des exemples : en développement SEULEMENT. Même double
        // sécurité que pour les offres : hors développement, le service n'est
        // pas enregistré, quel que soit le réglage.
        if (environment.IsDevelopment())
        {
            services.AddHostedService<SampleTrainingsImportService>();
        }

        return services;
    }
}

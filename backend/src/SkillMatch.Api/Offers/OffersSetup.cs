namespace SkillMatch.Api.Offers;

/// <summary>
/// Enregistre ce qui concerne les offres côté API. La lecture et l'import
/// (JobCatalog, JobImporter) sont enregistrés par AddInfrastructure.
/// </summary>
public static class OffersSetup
{
    public static IServiceCollection AddOffers(this IServiceCollection services, IHostEnvironment environment)
    {
        ArgumentNullException.ThrowIfNull(environment);

        services.AddOptions<JobsOptions>().BindConfiguration(JobsOptions.SectionName);

        // Import des exemples : en développement SEULEMENT (choix validé).
        // Double sécurité : même si « Jobs:ImportSampleOnStartup » était mis à
        // true par erreur en production, le service n'y serait pas enregistré.
        if (environment.IsDevelopment())
        {
            services.AddHostedService<SampleJobsImportService>();
        }

        return services;
    }
}

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SkillMatch.Core.Jobs;

namespace SkillMatch.Infrastructure.Persistence.Configurations;

/// <summary>
/// Correspondance entre <see cref="Job"/> et la table « jobs ».
/// Noms SQL en snake_case, comme pour la table users.
/// </summary>
internal sealed class JobConfiguration : IEntityTypeConfiguration<Job>
{
    public void Configure(EntityTypeBuilder<Job> builder)
    {
        builder.ToTable("jobs");

        builder.HasKey(j => j.Id).HasName("pk_jobs");

        // L'Id est créé par le domaine (Guid v7), pas par la base.
        builder.Property(j => j.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(j => j.Title)
            .HasColumnName("title")
            .HasMaxLength(Job.MaxTitleLength)
            .IsRequired();

        builder.Property(j => j.Company)
            .HasColumnName("company")
            .HasMaxLength(Job.MaxCompanyLength)
            .IsRequired();

        // Enregistré en texte (« stage », « pfe », « emploi ») : lisible en SQL.
        builder.Property(j => j.Type)
            .HasColumnName("type")
            .HasMaxLength(JobCodes.MaxCodeLength)
            .HasConversion(t => JobCodes.ToCode(t), c => JobCodes.ToJobType(c))
            .IsRequired();

        builder.Property(j => j.City)
            .HasColumnName("city")
            .HasMaxLength(Job.MaxCityLength)
            .IsRequired();

        builder.Property(j => j.Url)
            .HasColumnName("url")
            .HasMaxLength(Job.MaxUrlLength);

        builder.Property(j => j.Source)
            .HasColumnName("source")
            .HasMaxLength(Job.MaxSourceLength)
            .IsRequired();

        builder.Property(j => j.ExternalId)
            .HasColumnName("external_id")
            .HasMaxLength(Job.MaxExternalIdLength)
            .IsRequired();

        builder.Property(j => j.IsSample)
            .HasColumnName("is_sample")
            .IsRequired();

        builder.Property(j => j.PublishedAt)
            .HasColumnName("published_at")
            .IsRequired();

        builder.Property(j => j.ImportedAt)
            .HasColumnName("imported_at")
            .IsRequired();

        // Une offre par (source, identifiant chez la source) : réimporter la
        // même offre la met à jour au lieu de la dupliquer, même si deux
        // imports tournaient en même temps.
        builder.HasIndex(j => new { j.Source, j.ExternalId })
            .IsUnique()
            .HasDatabaseName("ix_jobs_source_external_id");

        // Compétences : supprimées avec leur offre (cascade). EF Core passe par
        // le champ privé _skills, l'offre gardant seule la main sur sa liste.
        builder.HasMany(j => j.Skills)
            .WithOne()
            .HasForeignKey(s => s.JobId)
            .HasConstraintName("fk_job_skills_jobs_job_id")
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(j => j.Skills)
            .HasField("_skills")
            .UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

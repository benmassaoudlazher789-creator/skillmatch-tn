using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SkillMatch.Core.Jobs;

namespace SkillMatch.Infrastructure.Persistence.Configurations;

/// <summary>Correspondance entre <see cref="JobSkill"/> et la table « job_skills ».</summary>
internal sealed class JobSkillConfiguration : IEntityTypeConfiguration<JobSkill>
{
    public void Configure(EntityTypeBuilder<JobSkill> builder)
    {
        builder.ToTable("job_skills");

        // Clé (offre, nom) : une compétence n'apparaît qu'une fois par offre,
        // donc jamais à la fois requise et souhaitée. Pas besoin d'Id à part.
        builder.HasKey(s => new { s.JobId, s.Name }).HasName("pk_job_skills");

        builder.Property(s => s.JobId)
            .HasColumnName("job_id");

        builder.Property(s => s.Name)
            .HasColumnName("name")
            .HasMaxLength(JobSkill.MaxNameLength)
            .IsRequired();

        // « required » ou « preferred », en texte, comme le type d'offre.
        builder.Property(s => s.Importance)
            .HasColumnName("importance")
            .HasMaxLength(JobCodes.MaxCodeLength)
            .HasConversion(i => JobCodes.ToCode(i), c => JobCodes.ToImportance(c))
            .IsRequired();
    }
}

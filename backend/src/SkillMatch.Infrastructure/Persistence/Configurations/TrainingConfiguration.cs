using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SkillMatch.Core.Trainings;

namespace SkillMatch.Infrastructure.Persistence.Configurations;

/// <summary>
/// Correspondance entre <see cref="Training"/> et la table « trainings ».
/// Noms SQL en snake_case, comme pour les tables users et jobs.
/// </summary>
internal sealed class TrainingConfiguration : IEntityTypeConfiguration<Training>
{
    public void Configure(EntityTypeBuilder<Training> builder)
    {
        builder.ToTable("trainings");

        builder.HasKey(t => t.Id).HasName("pk_trainings");

        // L'Id est créé par le domaine (Guid v7), pas par la base.
        builder.Property(t => t.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(t => t.Skill)
            .HasColumnName("skill")
            .HasMaxLength(Training.MaxSkillLength)
            .IsRequired();

        builder.Property(t => t.SkillKey)
            .HasColumnName("skill_key")
            .HasMaxLength(Training.MaxSkillKeyLength)
            .IsRequired();

        builder.Property(t => t.Title)
            .HasColumnName("title")
            .HasMaxLength(Training.MaxTitleLength)
            .IsRequired();

        // Enregistrés en texte (« debutant », « cours_en_ligne »…) : lisibles en SQL.
        builder.Property(t => t.Level)
            .HasColumnName("level")
            .HasMaxLength(TrainingCodes.MaxCodeLength)
            .HasConversion(l => TrainingCodes.ToCode(l), c => TrainingCodes.ToLevel(c))
            .IsRequired();

        builder.Property(t => t.Hours)
            .HasColumnName("hours")
            .IsRequired();

        builder.Property(t => t.Type)
            .HasColumnName("type")
            .HasMaxLength(TrainingCodes.MaxCodeLength)
            .HasConversion(t => TrainingCodes.ToCode(t), c => TrainingCodes.ToType(c))
            .IsRequired();

        builder.Property(t => t.Url)
            .HasColumnName("url")
            .HasMaxLength(Training.MaxUrlLength);

        builder.Property(t => t.Source)
            .HasColumnName("source")
            .HasMaxLength(Training.MaxSourceLength)
            .IsRequired();

        builder.Property(t => t.ExternalId)
            .HasColumnName("external_id")
            .HasMaxLength(Training.MaxExternalIdLength)
            .IsRequired();

        builder.Property(t => t.IsSample)
            .HasColumnName("is_sample")
            .IsRequired();

        builder.Property(t => t.ImportedAt)
            .HasColumnName("imported_at")
            .IsRequired();

        // Une formation par (source, identifiant chez la source) : réimporter
        // la même formation la met à jour au lieu de la dupliquer.
        builder.HasIndex(t => new { t.Source, t.ExternalId })
            .IsUnique()
            .HasDatabaseName("ix_trainings_source_external_id");

        // GET /trainings cherche toujours par compétence : sans cet index,
        // PostgreSQL lirait toute la table à chaque appel.
        builder.HasIndex(t => t.SkillKey)
            .HasDatabaseName("ix_trainings_skill_key");
    }
}

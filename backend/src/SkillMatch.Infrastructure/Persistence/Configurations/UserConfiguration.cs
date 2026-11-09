using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SkillMatch.Core.Users;

namespace SkillMatch.Infrastructure.Persistence.Configurations;

/// <summary>
/// Correspondance entre <see cref="User"/> et la table PostgreSQL « users ».
/// Les noms SQL sont écrits à la main (snake_case, l'usage PostgreSQL) plutôt
/// que via un paquet de conventions : un paquet en moins, et les noms se lisent ici.
/// </summary>
internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id).HasName("pk_users");

        // L'Id est créé par le domaine (Guid v7), pas par la base.
        builder.Property(u => u.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(u => u.FullName)
            .HasColumnName("full_name")
            .HasMaxLength(User.MaxFullNameLength)
            .IsRequired();

        builder.Property(u => u.Email)
            .HasColumnName("email")
            .HasMaxLength(User.MaxEmailLength)
            .IsRequired();

        builder.Property(u => u.PasswordHash)
            .HasColumnName("password_hash")
            .HasMaxLength(User.MaxPasswordHashLength)
            .IsRequired();

        // DateTimeOffset devient « timestamp with time zone » avec Npgsql.
        builder.Property(u => u.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        // Un seul compte par adresse. Un index simple suffit car le domaine
        // met déjà l'e-mail en minuscules (pas besoin de citext ni de lower()).
        builder.HasIndex(u => u.Email)
            .IsUnique()
            .HasDatabaseName("ix_users_email");
    }
}

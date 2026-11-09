using SkillMatch.Core.Users;

namespace SkillMatch.Tests.Users;

/// <summary>
/// Règles du domaine pour <see cref="User"/>. Aucune base : on teste
/// uniquement le code de SkillMatch.Core. Toutes les valeurs sont des exemples.
/// </summary>
public sealed class UserTests
{
    private const string NomExemple = "Candidat Exemple";
    private const string EmailExemple = "candidat@exemple.tn";
    private const string HashExemple = "hash-exemple";

    [Fact]
    public void Create_NormaliseEmailEtNom()
    {
        var user = User.Create("  Candidat Exemple ", "  Candidat@Exemple.TN ", HashExemple);

        Assert.Equal("candidat@exemple.tn", user.Email);
        Assert.Equal(NomExemple, user.FullName);
        Assert.Equal(HashExemple, user.PasswordHash);
    }

    [Fact]
    public void Create_GenereIdEtDateUtc()
    {
        var user = User.Create(NomExemple, EmailExemple, HashExemple);

        Assert.NotEqual(Guid.Empty, user.Id);
        // Npgsql n'accepte que des dates UTC pour timestamp with time zone.
        Assert.Equal(TimeSpan.Zero, user.CreatedAt.Offset);
    }

    // ThrowsAny et non Throws : null lance ArgumentNullException,
    // une sous-classe d'ArgumentException.
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_RefuseNomVide(string? fullName)
    {
        Assert.ThrowsAny<ArgumentException>(() => User.Create(fullName!, EmailExemple, HashExemple));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_RefuseEmailVide(string? email)
    {
        Assert.ThrowsAny<ArgumentException>(() => User.Create(NomExemple, email!, HashExemple));
    }

    [Fact]
    public void Create_RefuseEmailSansArobase()
    {
        Assert.Throws<ArgumentException>(() => User.Create(NomExemple, "exemple.tn", HashExemple));
    }

    [Fact]
    public void Create_RefuseNomTropLong()
    {
        var nomTropLong = new string('a', User.MaxFullNameLength + 1);

        Assert.Throws<ArgumentException>(() => User.Create(nomTropLong, EmailExemple, HashExemple));
    }

    [Fact]
    public void Create_AccepteNomALaLimite()
    {
        var nomLimite = new string('a', User.MaxFullNameLength);

        var user = User.Create(nomLimite, EmailExemple, HashExemple);

        Assert.Equal(User.MaxFullNameLength, user.FullName.Length);
    }
}

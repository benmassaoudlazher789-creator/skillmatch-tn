using SkillMatch.Api.Auth;
using SkillMatch.Infrastructure.Auth;

namespace SkillMatch.Tests.Auth;

/// <summary>
/// Règles du mot de passe : validation de l'API et hachage BCrypt.
/// Tests unitaires, sans serveur ni base. Toutes les valeurs sont des exemples.
/// </summary>
public sealed class PasswordTests
{
    // Facteur minimal : ces tests portent sur les règles, pas sur la lenteur.
    private static readonly BcryptPasswordHasher Hasher = new(BcryptPasswordHasher.MinWorkFactor);

    private static RegisterRequest Demande(string password) =>
        new("Candidat Exemple", "candidat@exemple.tn", password);

    [Fact]
    public void Validation_Accepte72OctetsEtRefuse73()
    {
        // « é » occupe 2 octets en UTF-8 : 36 « é » = 72 octets, mais 36 caractères.
        var password72 = new string('é', 36);
        var password73 = password72 + "a";

        Assert.Empty(AuthValidation.ValidateRegister(Demande(password72)));
        Assert.Contains("password", AuthValidation.ValidateRegister(Demande(password73)).Keys);
    }

    [Fact]
    public void Validation_RefuseMoinsDe8Caracteres()
    {
        Assert.Contains("password", AuthValidation.ValidateRegister(Demande("Court-7")).Keys);
    }

    [Fact]
    public void Hash_PuisVerify_AccepteLeBonMotDePasseSeulement()
    {
        const string password = "MotDePasse-Exemple-1";

        var hash = Hasher.Hash(password);

        Assert.StartsWith("$2", hash);
        Assert.DoesNotContain(password, hash);
        Assert.True(Hasher.Verify(password, hash));
        Assert.False(Hasher.Verify("Mauvais-Exemple-2", hash));
    }

    [Fact]
    public void Hash_RefusePlusDe72Octets()
    {
        Assert.Throws<ArgumentException>(() => Hasher.Hash(new string('a', 73)));
    }

    [Fact]
    public void Verify_RefuseUnMotDePasseAllonge()
    {
        // Sans le garde-fou, BCrypt couperait à 72 octets et accepterait ce mot de passe.
        var password72 = new string('a', 72);
        var hash = Hasher.Hash(password72);

        Assert.False(Hasher.Verify(password72 + "b", hash));
    }
}

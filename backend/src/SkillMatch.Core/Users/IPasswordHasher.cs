namespace SkillMatch.Core.Users;

/// <summary>
/// Calcul et contrôle du hash d'un mot de passe.
/// L'interface vit dans le domaine et l'implémentation (BCrypt) dans
/// l'infrastructure : Core reste sans paquet, et l'algorithme peut changer
/// sans toucher au reste du code.
/// </summary>
public interface IPasswordHasher
{
    /// <summary>Renvoie un hash salé ; deux appels sur le même mot de passe donnent deux hash différents.</summary>
    string Hash(string password);

    /// <summary>Indique si <paramref name="password"/> correspond au hash enregistré.</summary>
    bool Verify(string password, string passwordHash);

    /// <summary>
    /// Fait le même travail qu'un contrôle réel, sur un hash factice, et ignore le résultat.
    /// Sert quand l'e-mail est inconnu : la réponse prend alors autant de temps
    /// que pour un mauvais mot de passe, ce qui empêche de deviner les comptes existants.
    /// </summary>
    void VerifyAgainstDummyHash(string password);
}

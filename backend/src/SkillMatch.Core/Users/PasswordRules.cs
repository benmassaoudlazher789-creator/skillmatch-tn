using System.Text;

namespace SkillMatch.Core.Users;

/// <summary>
/// Règles de longueur d'un mot de passe, partagées par la validation de l'API
/// et par le hachage : une seule valeur, donc aucun écart possible entre les deux.
/// </summary>
public static class PasswordRules
{
    /// <summary>8 caractères au moins : en dessous, un mot de passe se devine trop vite.</summary>
    public const int MinLength = 8;

    /// <summary>
    /// BCrypt ne lit que les 72 premiers octets et ignore la suite sans prévenir.
    /// On refuse donc tout mot de passe plus long plutôt que de le couper en silence.
    /// On compte en octets UTF-8 : une lettre accentuée (é) en occupe 2.
    /// </summary>
    public const int MaxUtf8Bytes = 72;

    public static bool ExceedsMaxBytes(string password)
    {
        ArgumentNullException.ThrowIfNull(password);
        return Encoding.UTF8.GetByteCount(password) > MaxUtf8Bytes;
    }
}

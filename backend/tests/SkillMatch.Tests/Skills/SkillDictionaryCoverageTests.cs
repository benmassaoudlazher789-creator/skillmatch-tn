using SkillMatch.Core.Skills;

namespace SkillMatch.Tests.Skills;

/// <summary>
/// Compétences ajoutées au dictionnaire : chaque alias est essayé, puis les
/// pièges (mots courants qui ressemblent à un outil). Tous les textes sont
/// inventés pour les tests ; aucun ne vient d'un vrai CV.
///
/// On vérifie avec Contains dans les tests par alias : certains alias
/// trouvent aussi une autre compétence, de façon voulue (« GitHub Actions »
/// donne aussi GitHub). Les cas où la liste exacte compte utilisent Equal.
/// </summary>
public sealed class SkillDictionaryCoverageTests
{
    private static void AssertDetects(string text, string expected) =>
        Assert.Contains(expected, SkillDetector.Detect(text));

    [Theory]
    [InlineData("Express.js", "Express")]
    [InlineData("ExpressJS", "Express")]
    [InlineData("express js", "Express")]
    [InlineData("Node.js Express", "Express")]
    [InlineData("NodeJS / Express", "Express")]
    [InlineData("Node.js", "Node.js")]
    [InlineData("NodeJS", "Node.js")]
    [InlineData("node js", "Node.js")]
    [InlineData("React", "React")]
    [InlineData("ReactJS", "React")]
    [InlineData("Next.js", "Next.js")]
    [InlineData("NextJS", "Next.js")]
    [InlineData("next js", "Next.js")]
    [InlineData("MongoDB", "MongoDB")]
    [InlineData("Mongo", "MongoDB")]
    [InlineData("Mongo DB", "MongoDB")]
    [InlineData("REST API", "API REST")]
    [InlineData("APIs REST", "API REST")]
    [InlineData("services REST", "API REST")]
    [InlineData("RESTful", "API REST")]
    [InlineData("JWT", "JWT")]
    [InlineData("JSON Web Token", "JWT")]
    [InlineData("JSON Web Tokens", "JWT")]
    [InlineData("TypeScript", "TypeScript")]
    public void WebJs_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData("Flutter", "Flutter")]
    [InlineData("Dart", "Dart")]
    public void Mobile_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData(".NET", ".NET")]
    [InlineData("dot net", ".NET")]
    [InlineData("ASP.NET Core", ".NET")]
    [InlineData("C#", "C#")]
    [InlineData("C sharp", "C#")]
    [InlineData("PostgreSQL", "PostgreSQL")]
    [InlineData("Postgres", "PostgreSQL")]
    [InlineData("Postgre", "PostgreSQL")]
    [InlineData("psql", "PostgreSQL")]
    [InlineData("SQL", "SQL")]
    [InlineData("Python", "Python")]
    [InlineData("Python3", "Python")]
    [InlineData("Python 3", "Python")]
    public void Backend_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData("Docker", "Docker")]
    [InlineData("Dockerfile", "Docker")]
    [InlineData("Kubernetes", "Kubernetes")]
    [InlineData("k8s", "Kubernetes")]
    [InlineData("kubectl", "Kubernetes")]
    [InlineData("GitHub Actions", "GitHub Actions")]
    [InlineData("GitHub Action", "GitHub Actions")]
    [InlineData("CI/CD", "CI/CD")]
    [InlineData("CI CD", "CI/CD")]
    [InlineData("CI-CD", "CI/CD")]
    [InlineData("CICD", "CI/CD")]
    [InlineData("Intégration continue", "CI/CD")]
    [InlineData("Déploiement continu", "CI/CD")]
    [InlineData("Continuous Integration", "CI/CD")]
    [InlineData("Continuous Deployment", "CI/CD")]
    [InlineData("Continuous Delivery", "CI/CD")]
    [InlineData("Prometheus", "Prometheus")]
    [InlineData("Grafana", "Grafana")]
    [InlineData("SonarQube", "SonarQube")]
    [InlineData("Sonar Qube", "SonarQube")]
    [InlineData("Trivy", "Trivy")]
    [InlineData("Snyk", "Snyk")]
    [InlineData("Netlify", "Netlify")]
    [InlineData("Render.com", "Render")]
    public void DevOps_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData("ESP32", "ESP32")]
    [InlineData("ESP-32", "ESP32")]
    [InlineData("ESP 32", "ESP32")]
    [InlineData("ESP32-S3", "ESP32")]
    [InlineData("STM32", "STM32")]
    [InlineData("STM-32", "STM32")]
    [InlineData("STM32CubeIDE", "STM32")]
    [InlineData("STM32CubeMX", "STM32")]
    [InlineData("STM32F4", "STM32")]
    [InlineData("Arduino", "Arduino")]
    [InlineData("Arduino Uno", "Arduino")]
    public void Embarque_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData("CCNA", "CCNA")]
    [InlineData("Cisco", "Cisco")]
    [InlineData("Cisco Packet Tracer", "Cisco")]
    public void Reseaux_Detectes(string text, string expected) => AssertDetects(text, expected);

    [Theory]
    [InlineData("Git", "Git")]
    [InlineData("GitHub", "GitHub")]
    [InlineData("Linux", "Linux")]
    [InlineData("Debian", "Linux")]
    [InlineData("Red Hat", "Linux")]
    [InlineData("Deep Learning", "Deep Learning")]
    [InlineData("deep-learning", "Deep Learning")]
    [InlineData("Apprentissage profond", "Deep Learning")]
    [InlineData("Réseaux de neurones", "Deep Learning")]
    [InlineData("Neural networks", "Deep Learning")]
    [InlineData("Stripe", "Stripe")]
    public void Autres_Detectes(string text, string expected) => AssertDetects(text, expected);

    // ---- Cas où la liste exacte compte ----

    [Fact]
    public void Express_DansUneListeApresNodeJs()
    {
        // La virgule sépare les mots : « node.js » et « express » se suivent.
        Assert.Equal(
            new[] { "Node.js", "Express", "MongoDB" },
            SkillDetector.Detect("Node.js, Express, MongoDB"));
    }

    [Fact]
    public void GitEtGitHub_Distincts()
    {
        Assert.Equal(new[] { "GitHub" }, SkillDetector.Detect("GitHub"));
        Assert.Equal(new[] { "Git", "GitHub" }, SkillDetector.Detect("Git et GitHub"));
    }

    [Fact]
    public void GitHubActions_DonneAussiGitHub() =>
        Assert.Equal(new[] { "GitHub", "GitHub Actions" }, SkillDetector.Detect("GitHub Actions"));

    [Fact]
    public void CiscoCcna_DonneLesDeux() =>
        Assert.Equal(new[] { "CCNA", "Cisco" }, SkillDetector.Detect("Cisco CCNA"));

    [Fact]
    public void ReseauxDeNeurones_NeDonnePasReseaux() =>
        Assert.Equal(new[] { "Deep Learning" }, SkillDetector.Detect("Réseaux de neurones"));

    // ---- Faux positifs : aucun outil ne doit être trouvé ----

    [Theory]
    [InlineData("express delivery")]
    [InlineData("Livraison express")]
    [InlineData("Express")]
    [InlineData("Next step : entretien")]
    [InlineData("Render the page")]
    [InlineData("Rendu final du projet")]
    [InlineData("Salaire net mensuel")]
    [InlineData("Accès Internet")]
    [InlineData("CD audio")]
    [InlineData("Actions menées en équipe")]
    [InlineData("The rest of the team")]
    [InlineData("Un node du graphe")]
    [InlineData("Langues : ESP, ANG")]
    [InlineData("Google Drive")]
    [InlineData("Ordinateur 16 Go de RAM")]
    [InlineData("Note : C, mention R")]
    [InlineData("Réseaux sociaux")]
    public void FauxPositifs_RienDetecte(string text) =>
        Assert.Empty(SkillDetector.Detect(text));

    // ---- CV complet, inventé ----

    [Fact]
    public void CvRealisteFictif()
    {
        // Profil inventé (aucun nom, aucune coordonnée) qui mélange
        // majuscules, accents, parenthèses et ponctuation.
        const string cv = """
            PROFIL (EXEMPLE)
            Étudiant fictif en génie logiciel, à la recherche d'un stage de 6 mois.

            COMPÉTENCES
            Web : Node.js, Express, MongoDB, Next.js, TypeScript, API REST protégée par JWT.
            Mobile : Flutter et Dart.
            Backend : ASP.NET Core (C#), PostgreSQL, SQL, Python 3.
            DevOps : Docker, k8s, pipelines CI/CD avec GitHub Actions ;
            supervision Prometheus + Grafana ; analyse SonarQube, Trivy et Snyk ;
            mise en ligne sur Netlify et Render.com.
            Embarqué : ESP32, STM32CubeIDE, Arduino.
            Réseaux : CCNA, Cisco Packet Tracer.
            Divers : Git, GitHub, Linux (Ubuntu), Deep Learning, paiement Stripe.

            LANGUES
            Français, anglais.
            """;

        // Ordre attendu : celui du dictionnaire, pas celui du texte.
        Assert.Equal(
            new[]
            {
                "Dart", "Python", "TypeScript", "C#", "SQL",
                "Flutter", "Node.js", "Express", "Next.js", ".NET",
                "PostgreSQL", "MongoDB", "Deep Learning",
                "Git", "GitHub", "Docker", "Kubernetes", "CI/CD", "GitHub Actions",
                "Prometheus", "Grafana", "SonarQube", "Trivy", "Snyk", "Netlify", "Render",
                "API REST", "JWT", "Stripe",
                "Linux", "CCNA", "Cisco",
                "ESP32", "STM32", "Arduino",
            },
            SkillDetector.Detect(cv));
    }
}

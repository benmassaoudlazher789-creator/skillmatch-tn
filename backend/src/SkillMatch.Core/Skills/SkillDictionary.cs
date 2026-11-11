namespace SkillMatch.Core.Skills;

/// <summary>
/// Une compétence : le nom affiché dans l'application et les façons de
/// l'écrire dans un CV. Majuscules et accents ne comptent pas (voir
/// TextNormalizer) : inutile d'écrire « Excel » et « excel ».
/// </summary>
public sealed record SkillEntry(string Name, IReadOnlyList<string> Variants);

/// <summary>
/// Dictionnaire des compétences reconnues.
///
/// Pourquoi une liste écrite à la main plutôt qu'une IA ? Le résultat est
/// prévisible, expliqué ligne par ligne et testé. Limite assumée : une
/// compétence absente de la liste n'est pas détectée ; le candidat peut
/// l'ajouter lui-même dans l'application.
///
/// Les noms reprennent ceux des offres et formations de l'application
/// (« Power BI », « API REST », « Réseaux »…) pour que la comparaison
/// fonctionne.
///
/// Mots ambigus : un nom très court ou un mot courant n'est reconnu que par
/// une forme sans ambiguïté. « Go » seul est un mot ordinaire : on exige
/// « golang ». « Vue » est un mot français : on exige « vue.js » ou « vuejs ».
/// </summary>
public static class SkillDictionary
{
    public static IReadOnlyList<SkillEntry> Default { get; } =
    [
        // ---- Langages ----
        new("Dart", ["dart"]),
        new("Python", ["python"]),
        new("Java", ["java"]),
        new("JavaScript", ["javascript", "js", "ecmascript"]),
        new("TypeScript", ["typescript"]),
        new("PHP", ["php"]),
        new("C#", ["c#", "csharp"]),
        new("C++", ["c++", "cpp"]),
        // « C » seul : une lettre, trop ambiguë (initiale, note, « C1 »…).
        new("C", ["langage c", "language c", "programmation c"]),
        new("Kotlin", ["kotlin"]),
        new("Swift", ["swift"]),
        // « Go » seul est un mot ordinaire (« 2 Go de mémoire ») : forme exigée.
        new("Go", ["golang"]),
        // « R » seul : une lettre, trop ambiguë.
        new("R", ["langage r", "language r", "rstudio"]),
        new("SQL", ["sql"]),
        new("HTML", ["html", "html5"]),
        new("CSS", ["css", "css3"]),

        // ---- Frameworks et bibliothèques ----
        new("Flutter", ["flutter"]),
        new("React", ["react", "react.js", "reactjs"]),
        new("React Native", ["react native"]),
        new("Angular", ["angular", "angularjs"]),
        // « Vue » est un mot français : forme exigée.
        new("Vue.js", ["vue.js", "vuejs"]),
        new("Node.js", ["node.js", "nodejs"]),
        new(".NET", [".net", "dotnet", "asp.net", "asp.net core"]),
        new("Spring Boot", ["spring boot", "spring framework"]),
        new("Django", ["django"]),
        new("Flask", ["flask"]),
        new("Laravel", ["laravel"]),
        new("Symfony", ["symfony"]),
        new("Bootstrap", ["bootstrap"]),
        new("Tailwind CSS", ["tailwind", "tailwindcss", "tailwind css"]),
        new("Pandas", ["pandas"]),
        new("NumPy", ["numpy"]),
        new("Scikit-learn", ["scikit-learn", "sklearn"]),
        new("TensorFlow", ["tensorflow"]),
        new("PyTorch", ["pytorch"]),

        // ---- Données ----
        new("PostgreSQL", ["postgresql", "postgres"]),
        new("MySQL", ["mysql"]),
        new("MongoDB", ["mongodb"]),
        new("Redis", ["redis"]),
        new("Firebase", ["firebase"]),
        new("Power BI", ["power bi", "powerbi"]),
        // « Tableau » est un mot français : forme exigée.
        new("Tableau", ["tableau software", "tableau desktop"]),
        new("Machine learning", ["machine learning", "apprentissage automatique"]),
        new("Apache Spark", ["apache spark", "pyspark"]),

        // ---- Outils, cloud, méthodes ----
        new("Git", ["git", "github", "gitlab"]),
        new("Docker", ["docker"]),
        new("Kubernetes", ["kubernetes", "k8s"]),
        new("Jenkins", ["jenkins"]),
        new("CI/CD", ["ci/cd", "integration continue"]),
        new("AWS", ["aws", "amazon web services"]),
        new("Azure", ["azure", "microsoft azure"]),
        new("Google Cloud", ["google cloud", "gcp"]),
        new("API REST", ["api rest", "rest api", "api restful", "restful"]),
        new("GraphQL", ["graphql"]),
        new("Postman", ["postman"]),
        new("Tests unitaires", ["tests unitaires", "test unitaire", "unit test", "unit tests", "unit testing"]),
        new("Selenium", ["selenium"]),
        new("Jira", ["jira"]),
        new("Scrum", ["scrum"]),
        new("Agile", ["agile", "methode agile", "methodes agiles"]),
        new("UML", ["uml"]),

        // ---- Systèmes et réseaux ----
        new("Linux", ["linux", "ubuntu"]),
        new("Windows", ["windows", "windows server"]),
        // « Réseau » seul est trop large (« réseaux sociaux ») : formes exigées.
        new("Réseaux", ["reseaux informatiques", "reseau informatique", "administration reseau", "administration reseaux", "tcp/ip", "networking"]),
        new("Android", ["android"]),

        // ---- Bureautique et design ----
        new("Excel", ["excel", "ms excel", "microsoft excel"]),
        // « Word » seul est un mot anglais courant : forme exigée.
        new("Word", ["microsoft word", "ms word"]),
        new("PowerPoint", ["powerpoint", "power point"]),
        new("Figma", ["figma"]),
        new("Photoshop", ["photoshop"]),
        new("Illustrator", ["illustrator"]),
        new("Adobe XD", ["adobe xd"]),

        // ---- Ingénierie ----
        new("AutoCAD", ["autocad"]),
        new("SolidWorks", ["solidworks"]),
        new("MATLAB", ["matlab"]),
        new("SAP", ["sap"]),
    ];
}

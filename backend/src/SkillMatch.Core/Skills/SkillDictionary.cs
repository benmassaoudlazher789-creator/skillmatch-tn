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
        // « python3 » est un seul mot ; « Python 3 » est déjà trouvé par « python ».
        new("Python", ["python", "python3"]),
        new("Java", ["java"]),
        new("JavaScript", ["javascript", "js", "ecmascript"]),
        new("TypeScript", ["typescript"]),
        new("PHP", ["php"]),
        new("C#", ["c#", "csharp", "c sharp"]),
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
        // « node » seul n'est pas retenu : c'est aussi un nœud de graphe.
        // « node js » (deux mots) contient « js » : JavaScript est aussi trouvé,
        // ce qui est cohérent.
        new("Node.js", ["node.js", "nodejs", "node js"]),
        // « Express » est un mot courant (« livraison express ») : on exige
        // « express.js », ou « Express » juste après Node.js, comme dans la
        // liste « Node.js, Express, MongoDB » (la virgule sépare les mots,
        // donc « node.js » et « express » se suivent).
        new("Express", ["express.js", "expressjs", "express js", "node.js express", "nodejs express"]),
        // « Next » seul est un mot anglais courant (« next step ») : forme exigée.
        new("Next.js", ["next.js", "nextjs", "next js"]),
        // « net » seul (« salaire net ») n'est pas une variante : le point de
        // « .net » est gardé par le découpage en mots.
        new(".NET", [".net", "dotnet", "dot net", "asp.net", "asp.net core"]),
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
        // « Postgre » : faute de frappe fréquente dans les CV.
        new("PostgreSQL", ["postgresql", "postgres", "postgre", "psql"]),
        new("MySQL", ["mysql"]),
        new("MongoDB", ["mongodb", "mongo", "mongo db"]),
        new("Redis", ["redis"]),
        new("Firebase", ["firebase"]),
        new("Power BI", ["power bi", "powerbi"]),
        // « Tableau » est un mot français : forme exigée.
        new("Tableau", ["tableau software", "tableau desktop"]),
        new("Machine learning", ["machine learning", "apprentissage automatique"]),
        // « réseaux de neurones » ne déclenche pas « Réseaux » : cette entrée
        // exige « réseaux informatiques » ou une autre forme précise.
        new("Deep Learning", ["deep learning", "apprentissage profond", "reseaux de neurones", "reseau de neurones", "neural networks"]),
        new("Apache Spark", ["apache spark", "pyspark"]),

        // ---- Outils, cloud, méthodes ----
        // GitHub est une entrée à part (choix validé) : un CV qui ne cite que
        // GitHub n'a donc pas « Git » pour les offres qui demandent Git.
        new("Git", ["git", "gitlab"]),
        new("GitHub", ["github"]),
        new("Docker", ["docker", "dockerfile"]),
        new("Kubernetes", ["kubernetes", "k8s", "kubectl"]),
        new("Jenkins", ["jenkins"]),
        // « CI CD » et « CI-CD » donnent les mêmes mots que « ci/cd » (la barre
        // et le tiret séparent) : une seule variante suffit. « CD » seul (le
        // disque) n'est pas une variante.
        new("CI/CD", ["ci/cd", "cicd", "integration continue", "deploiement continu", "continuous integration", "continuous deployment", "continuous delivery"]),
        // « Actions » seul est un mot courant : on exige « GitHub Actions ».
        // GitHub est alors trouvé aussi, comme React avec React Native.
        new("GitHub Actions", ["github actions", "github action"]),
        new("Prometheus", ["prometheus"]),
        new("Grafana", ["grafana"]),
        // « Sonar » seul désigne aussi un appareil : forme exigée.
        new("SonarQube", ["sonarqube", "sonar qube"]),
        new("Trivy", ["trivy"]),
        new("Snyk", ["snyk"]),
        new("Netlify", ["netlify"]),
        // « Render » est un mot courant (« render », rendu d'une page) : on
        // exige l'adresse de l'hébergeur (choix validé).
        new("Render", ["render.com"]),
        new("AWS", ["aws", "amazon web services"]),
        new("Azure", ["azure", "microsoft azure"]),
        new("Google Cloud", ["google cloud", "gcp"]),
        // « Rest » seul (« the rest », « le reste ») n'est pas une variante.
        new("API REST", ["api rest", "rest api", "api restful", "restful", "rest apis", "apis rest", "services rest"]),
        new("JWT", ["jwt", "json web token", "json web tokens"]),
        new("GraphQL", ["graphql"]),
        new("Postman", ["postman"]),
        new("Stripe", ["stripe"]),
        new("Tests unitaires", ["tests unitaires", "test unitaire", "unit test", "unit tests", "unit testing"]),
        new("Selenium", ["selenium"]),
        new("Jira", ["jira"]),
        new("Scrum", ["scrum"]),
        new("Agile", ["agile", "methode agile", "methodes agiles"]),
        new("UML", ["uml"]),

        // ---- Systèmes et réseaux ----
        // Une distribution citée seule montre aussi la pratique de Linux.
        new("Linux", ["linux", "ubuntu", "debian", "centos", "red hat", "rhel", "fedora"]),
        new("Windows", ["windows", "windows server"]),
        // « Réseau » seul est trop large (« réseaux sociaux ») : formes exigées.
        new("Réseaux", ["reseaux informatiques", "reseau informatique", "administration reseau", "administration reseaux", "tcp/ip", "networking"]),
        new("CCNA", ["ccna"]),
        // « Packet Tracer » est le simulateur de réseau de Cisco.
        new("Cisco", ["cisco", "packet tracer"]),
        new("Android", ["android"]),

        // ---- Embarqué ----
        // « ESP » seul (abréviation d'« espagnol ») n'est pas une variante.
        new("ESP32", ["esp32", "esp 32"]),
        // Les noms de cartes collent souvent la famille au nom (« STM32F4 ») :
        // le découpage en mots entiers oblige à lister les plus courantes.
        new("STM32", ["stm32", "stm 32", "stm32cubeide", "stm32cubemx", "stm32f1", "stm32f4", "stm32l4"]),
        new("Arduino", ["arduino"]),

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

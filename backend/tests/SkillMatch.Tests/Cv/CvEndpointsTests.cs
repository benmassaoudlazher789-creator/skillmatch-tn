using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using DocumentFormat.OpenXml;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SkillMatch.Api.Auth;
using SkillMatch.Api.Cv;
using SkillMatch.Core.Cv;
using SkillMatch.Core.Users;

namespace SkillMatch.Tests.Cv;

/// <summary>
/// Tests de bout en bout de POST /cv : l'API tourne en mémoire, les CV sont
/// fabriqués pendant le test avec un texte fictif.
/// </summary>
public sealed class CvEndpointsTests(SkillMatchApiFactory factory)
    : IClassFixture<SkillMatchApiFactory>
{
    // Formes attendues des réponses, écrites ici plutôt que reprises de l'API.
    private sealed record SkillsBody(List<string> Skills);

    private sealed record ErrorBody(string Code, string Title);

    // ---- Jeton ----

    [Fact]
    public async Task SansJeton_401()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.SendAsync(Upload(CvTestFiles.Pdf("Flutter"), "cv.pdf", token: null), ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task JetonInvalide_401()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.SendAsync(
            Upload(CvTestFiles.Pdf("Flutter"), "cv.pdf", token: "jeton-invente-exemple"), ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ---- Succès ----

    [Fact]
    public async Task Pdf_200_CompetencesDetectees()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var pdf = CvTestFiles.Pdf(
            "Candidat Exemple - Developpeur mobile",
            "Competences : Flutter, Dart, SQL et Git.",
            "Notions de JavaScript.");

        using var response = await client.SendAsync(Upload(pdf, "cv.pdf", CreateToken()), ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<SkillsBody>(ct);
        Assert.NotNull(body);
        Assert.Equal(new[] { "Dart", "JavaScript", "SQL", "Flutter", "Git" }, body.Skills);
    }

    [Fact]
    public async Task Docx_200_AvecAccents()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var docx = CvTestFiles.Docx("Développement mobile avec FLUTTER\nAdministration réseaux sous Linux");

        using var response = await client.SendAsync(Upload(docx, "cv.docx", CreateToken()), ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<SkillsBody>(ct);
        Assert.NotNull(body);
        Assert.Equal(new[] { "Flutter", "Linux", "Réseaux" }, body.Skills);
    }

    [Fact]
    public async Task AucuneCompetenceConnue_200_ListeVide()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.SendAsync(
            Upload(CvTestFiles.Pdf("Experience en vente et accueil."), "cv.pdf", CreateToken()), ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<SkillsBody>(ct);
        Assert.NotNull(body);
        Assert.Empty(body.Skills);
    }

    [Fact]
    public async Task LeNomDuFichierNeComptePas()
    {
        // Un vrai PDF nommé « .docx » est accepté : seul le contenu compte.
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();

        using var response = await client.SendAsync(
            Upload(CvTestFiles.Pdf("Python"), "mauvais-nom.docx", CreateToken()), ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ---- Type refusé (signature) ----

    [Fact]
    public async Task TexteRenommeEnPdf_415() =>
        await AssertErrorAsync(
            Upload(CvTestFiles.PlainText(), "cv.pdf", CreateToken()),
            HttpStatusCode.UnsupportedMediaType,
            CvErrorCodes.UnsupportedType);

    [Fact]
    public async Task ZipRenommeEnDocx_415() =>
        await AssertErrorAsync(
            Upload(CvTestFiles.PlainZip(), "cv.docx", CreateToken()),
            HttpStatusCode.UnsupportedMediaType,
            CvErrorCodes.UnsupportedType);

    [Fact]
    public async Task DocxAMacros_415() =>
        await AssertErrorAsync(
            Upload(CvTestFiles.Docx("Flutter", WordprocessingDocumentType.MacroEnabledDocument), "cv.docx", CreateToken()),
            HttpStatusCode.UnsupportedMediaType,
            CvErrorCodes.UnsupportedType);

    // ---- Taille ----

    [Fact]
    public async Task UnOctetDeTrop_413()
    {
        // Signature PDF, puis des zéros : 5 Mo + 1 octet.
        var content = new byte[CvLimits.MaxFileBytes + 1];
        "%PDF-1.7"u8.CopyTo(content);

        await AssertErrorAsync(
            Upload(content, "cv.pdf", CreateToken()),
            HttpStatusCode.RequestEntityTooLarge,
            CvErrorCodes.TooLarge);
    }

    [Fact]
    public async Task RequeteBienTropGrosse_413()
    {
        // Au-delà de la limite de la requête entière : refusé sur la taille annoncée.
        var content = new byte[CvEndpoints.MaxRequestBytes + 1024];
        "%PDF-1.7"u8.CopyTo(content);

        await AssertErrorAsync(
            Upload(content, "cv.pdf", CreateToken()),
            HttpStatusCode.RequestEntityTooLarge,
            CvErrorCodes.TooLarge);
    }

    // ---- Contenu illisible ----

    [Fact]
    public async Task PdfSansTexte_422() =>
        await AssertErrorAsync(
            Upload(CvTestFiles.PdfWithoutText(), "cv.pdf", CreateToken()),
            HttpStatusCode.UnprocessableEntity,
            CvErrorCodes.NoText);

    [Fact]
    public async Task PdfAbime_422()
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        var content = Encoding.ASCII.GetBytes("%PDF-1.7\nceci n'est pas un vrai PDF");

        using var response = await client.SendAsync(Upload(content, "cv.pdf", CreateToken()), ct);

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    // ---- Formulaire ----

    [Fact]
    public async Task FichierVide_400() =>
        await AssertErrorAsync(
            Upload([], "cv.pdf", CreateToken()),
            HttpStatusCode.BadRequest,
            CvErrorCodes.Empty);

    [Fact]
    public async Task MauvaisNomDeChamp_400() =>
        await AssertErrorAsync(
            Upload(CvTestFiles.Pdf("Flutter"), "cv.pdf", CreateToken(), fieldName: "document"),
            HttpStatusCode.BadRequest,
            CvErrorCodes.NoFile);

    [Fact]
    public async Task DeuxFichiers_400()
    {
        var form = new MultipartFormDataContent
        {
            { new ByteArrayContent(CvTestFiles.Pdf("Flutter")), CvEndpoints.FileFieldName, "cv1.pdf" },
            { new ByteArrayContent(CvTestFiles.Pdf("Dart")), CvEndpoints.FileFieldName, "cv2.pdf" },
        };
        var request = new HttpRequestMessage(HttpMethod.Post, "/cv") { Content = form };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken());

        await AssertErrorAsync(request, HttpStatusCode.BadRequest, CvErrorCodes.TooManyFiles);
    }

    [Fact]
    public async Task PasUnFormulaire_400()
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/cv")
        {
            Content = JsonContent.Create(new { file = "exemple" }),
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken());

        await AssertErrorAsync(request, HttpStatusCode.BadRequest, CvErrorCodes.InvalidRequest);
    }

    // ---- Limite d'analyses ----

    [Fact]
    public async Task AnalyseAuDelaDeLaLimite_429()
    {
        var ct = TestContext.Current.CancellationToken;
        using var limitedFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, config) =>
                config.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["RateLimiting:Cv:PermitLimit"] = "1",
                })));
        using var client = limitedFactory.CreateClient();
        // Même compte pour les deux envois : le compteur est par compte.
        var token = CreateToken(limitedFactory);

        using var first = await client.SendAsync(Upload(CvTestFiles.Pdf("Flutter"), "cv.pdf", token), ct);
        using var second = await client.SendAsync(Upload(CvTestFiles.Pdf("Flutter"), "cv.pdf", token), ct);

        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        Assert.Equal(HttpStatusCode.TooManyRequests, second.StatusCode);
    }

    // ---- Confidentialité des journaux ----

    [Fact]
    public async Task Journaux_SeulementStatutEtDuree()
    {
        var ct = TestContext.Current.CancellationToken;
        var logs = new CapturingLoggerProvider();
        using var loggedFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureLogging(logging => logging.AddProvider(logs)));
        using var client = loggedFactory.CreateClient();

        // Marqueurs fictifs : ils ne doivent apparaître dans AUCUN message.
        const string secretText = "MarqueurConfidentielExemple";
        const string secretFileName = "CV_Candidat_Exemple_Marqueur.pdf";
        var pdf = CvTestFiles.Pdf($"{secretText} Flutter Docker");

        using var ok = await client.SendAsync(Upload(pdf, secretFileName, CreateToken(loggedFactory)), ct);
        using var refused = await client.SendAsync(
            Upload(Encoding.ASCII.GetBytes($"%PDF-1.7 {secretText}"), secretFileName, CreateToken(loggedFactory)), ct);

        Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, refused.StatusCode);

        var all = logs.Messages.ToList();
        Assert.Contains(all, m => m.Contains("Analyse de CV : statut 200", StringComparison.Ordinal));
        Assert.Contains(all, m => m.Contains("Analyse de CV : statut 422", StringComparison.Ordinal));
        foreach (var message in all)
        {
            Assert.DoesNotContain(secretText, message, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("CV_Candidat", message, StringComparison.OrdinalIgnoreCase);
            // Compétences détectées : jamais dans les journaux (choix validé).
            Assert.DoesNotContain("Flutter", message, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("Docker", message, StringComparison.OrdinalIgnoreCase);
        }
    }

    // ---- Outils ----

    /// <summary>
    /// Jeton valide pour un compte d'exemple. Le compte n'est pas en base :
    /// /cv ne lit que le jeton signé, pas la table users.
    /// </summary>
    private string CreateToken() => CreateToken(factory);

    private static string CreateToken(WebApplicationFactory<Program> apiFactory)
    {
        var user = User.Create("Candidat Exemple", $"candidat-{Guid.NewGuid():N}@exemple.tn", "hash-exemple");
        return apiFactory.Services.GetRequiredService<TokenService>().CreateToken(user);
    }

    private static HttpRequestMessage Upload(
        byte[] content,
        string fileName,
        string? token,
        string fieldName = CvEndpoints.FileFieldName)
    {
        var file = new ByteArrayContent(content);
        file.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");

        var request = new HttpRequestMessage(HttpMethod.Post, "/cv")
        {
            Content = new MultipartFormDataContent { { file, fieldName, fileName } },
        };
        if (token is not null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        return request;
    }

    private async Task AssertErrorAsync(HttpRequestMessage request, HttpStatusCode expectedStatus, string expectedCode)
    {
        var ct = TestContext.Current.CancellationToken;
        using var client = factory.CreateClient();
        using (request)
        {
            using var response = await client.SendAsync(request, ct);

            Assert.Equal(expectedStatus, response.StatusCode);
            var body = await response.Content.ReadFromJsonAsync<ErrorBody>(ct);
            Assert.NotNull(body);
            Assert.Equal(expectedCode, body.Code);
            Assert.False(string.IsNullOrWhiteSpace(body.Title));
        }
    }

    /// <summary>Garde en mémoire chaque message écrit dans les journaux.</summary>
    private sealed class CapturingLoggerProvider : ILoggerProvider
    {
        public ConcurrentQueue<string> Messages { get; } = new();

        public ILogger CreateLogger(string categoryName) => new CapturingLogger(this, categoryName);

        public void Dispose()
        {
        }

        private sealed class CapturingLogger(CapturingLoggerProvider provider, string category) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state)
                where TState : notnull => null;

            public bool IsEnabled(LogLevel logLevel) => true;

            public void Log<TState>(
                LogLevel logLevel,
                EventId eventId,
                TState state,
                Exception? exception,
                Func<TState, Exception?, string> formatter)
            {
                ArgumentNullException.ThrowIfNull(formatter);
                // Message, exception éventuelle ET valeurs brutes : rien ne doit y fuir.
                provider.Messages.Enqueue($"{category} | {formatter(state, exception)} | {exception} | {state}");
            }
        }
    }
}

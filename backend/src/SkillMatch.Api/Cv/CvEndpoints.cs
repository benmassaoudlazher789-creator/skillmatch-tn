using System.Diagnostics;
using Microsoft.AspNetCore.Http.Features;
using SkillMatch.Core.Cv;

namespace SkillMatch.Api.Cv;

/// <summary>
/// Route POST /cv : reçoit un CV (PDF ou DOCX, 5 Mo au plus) et renvoie les
/// compétences détectées.
///
/// Confidentialité (choix validé) :
/// - le fichier est lu en mémoire puis oublié : rien en base, rien sur le disque ;
/// - le nom du fichier envoyé n'est jamais lu ;
/// - le journal ne contient que le code de réponse et la durée : ni nom de
///   fichier, ni texte, ni compétences.
/// </summary>
public static class CvEndpoints
{
    /// <summary>Nom de la politique de limite d'analyses (voir CvSetup).</summary>
    public const string RateLimitPolicy = "cv";

    /// <summary>Nom du champ du formulaire qui contient le fichier.</summary>
    public const string FileFieldName = "file";

    /// <summary>
    /// Taille maximale de la requête entière : le fichier (5 Mo) plus une
    /// marge pour les en-têtes du formulaire multipart.
    /// </summary>
    public const long MaxRequestBytes = CvLimits.MaxFileBytes + (64 * 1024);

    private const string LoggerCategory = "SkillMatch.Api.Cv";

    /// <summary>
    /// Réglages de lecture du formulaire, propres à cette route.
    ///
    /// MemoryBufferThreshold : par défaut, ASP.NET écrit sur le disque (dossier
    /// temporaire) tout fichier reçu de plus de 64 Ko. En relevant ce seuil
    /// au-dessus de la taille maximale, le CV reste en mémoire et ne touche
    /// jamais le disque.
    /// </summary>
    private static readonly FormOptions UploadFormOptions = new()
    {
        MemoryBufferThreshold = (int)MaxRequestBytes,
        MultipartBodyLengthLimit = MaxRequestBytes,
        // Un seul fichier est attendu : peu de champs, et courts.
        ValueCountLimit = 8,
        ValueLengthLimit = 1024,
        KeyLengthLimit = 256,
    };

    public static IEndpointRouteBuilder MapCvEndpoints(this IEndpointRouteBuilder app)
    {
        // RequireAuthorization : sans jeton valide, réponse 401 avant même
        // d'entrer ici. Le formulaire est lu à la main (pas de paramètre
        // IFormFile) : on choisit ainsi les limites et le stockage en mémoire.
        // La protection « antiforgery » ne s'applique pas : elle vise les
        // cookies, alors que le jeton voyage dans un en-tête que le navigateur
        // n'envoie jamais de lui-même.
        app.MapPost("/cv", AnalyzeAsync)
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicy);

        return app;
    }

    private static async Task<IResult> AnalyzeAsync(
        HttpContext httpContext,
        CvAnalyzer analyzer,
        ILoggerFactory loggerFactory,
        CancellationToken cancellationToken)
    {
        var started = Stopwatch.GetTimestamp();

        var (statusCode, body) = await HandleAsync(httpContext, analyzer, cancellationToken);

        // Seulement le statut et la durée (choix validé).
        loggerFactory.CreateLogger(LoggerCategory).LogInformation(
            "Analyse de CV : statut {StatusCode} en {ElapsedMs} ms.",
            statusCode,
            (long)Stopwatch.GetElapsedTime(started).TotalMilliseconds);

        return Results.Json(body, statusCode: statusCode);
    }

    private static async Task<(int StatusCode, object Body)> HandleAsync(
        HttpContext httpContext,
        CvAnalyzer analyzer,
        CancellationToken cancellationToken)
    {
        var request = httpContext.Request;

        // Limite du serveur web (Kestrel) pour CETTE requête : il coupe la
        // lecture au-delà, même si le téléphone n'annonce pas la taille.
        if (httpContext.Features.Get<IHttpMaxRequestBodySizeFeature>() is { IsReadOnly: false } sizeFeature)
        {
            sizeFeature.MaxRequestBodySize = MaxRequestBytes;
        }

        // Taille annoncée trop grande : refus immédiat, sans rien lire.
        if (request.ContentLength > MaxRequestBytes)
        {
            return Error(CvError.TooLarge);
        }

        if (!request.HasFormContentType)
        {
            return (StatusCodes.Status400BadRequest, new CvErrorResponse(
                CvErrorCodes.InvalidRequest,
                "Envoyez le CV dans un formulaire multipart/form-data, champ « file »."));
        }

        IFormCollection form;
        try
        {
            form = await request.ReadFormAsync(UploadFormOptions, cancellationToken);
        }
        catch (BadHttpRequestException ex) when (ex.StatusCode == StatusCodes.Status413PayloadTooLarge)
        {
            return Error(CvError.TooLarge);
        }
        catch (InvalidDataException)
        {
            // Formulaire mal construit ou hors limites (trop de champs…).
            return (StatusCodes.Status400BadRequest, new CvErrorResponse(
                CvErrorCodes.InvalidRequest,
                "Le formulaire envoyé n'est pas valide."));
        }

        if (form.Files.Count > 1)
        {
            return (StatusCodes.Status400BadRequest, new CvErrorResponse(
                CvErrorCodes.TooManyFiles,
                "Envoyez un seul fichier à la fois."));
        }

        var file = form.Files.GetFile(FileFieldName);
        if (file is null)
        {
            return (StatusCodes.Status400BadRequest, new CvErrorResponse(
                CvErrorCodes.NoFile,
                "Aucun fichier reçu : joignez votre CV dans le champ « file »."));
        }

        // Contrôlé avant la copie : on ne réserve pas de mémoire pour rien.
        if (file.Length > CvLimits.MaxFileBytes)
        {
            return Error(CvError.TooLarge);
        }

        // Copie en mémoire (5 Mo au plus). file.FileName n'est jamais lu.
        var content = new byte[file.Length];
        await using (var stream = file.OpenReadStream())
        {
            await stream.ReadExactlyAsync(content, cancellationToken);
        }

        var result = analyzer.Analyze(content, cancellationToken);
        if (result.Error is { } error)
        {
            return Error(error);
        }

        return (StatusCodes.Status200OK, new CvAnalysisResponse(result.Skills));
    }

    /// <summary>Traduit une raison d'échec en code HTTP et en message français.</summary>
    private static (int StatusCode, object Body) Error(CvError error) => error switch
    {
        CvError.Empty => (StatusCodes.Status400BadRequest, new CvErrorResponse(
            CvErrorCodes.Empty,
            "Ce fichier est vide.")),
        CvError.TooLarge => (StatusCodes.Status413PayloadTooLarge, new CvErrorResponse(
            CvErrorCodes.TooLarge,
            "Fichier trop volumineux : la taille maximale est de 5 Mo.")),
        CvError.UnsupportedType => (StatusCodes.Status415UnsupportedMediaType, new CvErrorResponse(
            CvErrorCodes.UnsupportedType,
            "Format non accepté : envoyez un fichier PDF ou DOCX.")),
        CvError.PasswordProtected => (StatusCodes.Status422UnprocessableEntity, new CvErrorResponse(
            CvErrorCodes.PasswordProtected,
            "Ce fichier est protégé par un mot de passe. Envoyez une version sans protection.")),
        CvError.Unreadable => (StatusCodes.Status422UnprocessableEntity, new CvErrorResponse(
            CvErrorCodes.Unreadable,
            "Impossible de lire ce fichier. Enregistrez-le de nouveau en PDF ou en DOCX, puis réessayez.")),
        CvError.NoText => (StatusCodes.Status422UnprocessableEntity, new CvErrorResponse(
            CvErrorCodes.NoText,
            "Aucun texte trouvé dans ce fichier. S'il s'agit d'un CV scanné (une image), envoyez une version texte.")),
        _ => throw new UnreachableException($"Erreur de CV non prévue : {error}."),
    };
}

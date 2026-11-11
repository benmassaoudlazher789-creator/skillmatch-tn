using System.Text;
using SkillMatch.Core.Cv;

namespace SkillMatch.Tests.Cv;

/// <summary>Type reconnu par la signature (premiers octets) : fonction pure.</summary>
public sealed class CvFileTypeTests
{
    [Fact]
    public void DebutPdf_EstUnPdf() =>
        Assert.Equal(CvFileKind.Pdf, CvFileType.Detect("%PDF-1.7\n..."u8));

    [Fact]
    public void DebutZip_EstUnDocxCandidat() =>
        Assert.Equal(CvFileKind.Docx, CvFileType.Detect([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00]));

    [Theory]
    [InlineData("")]
    [InlineData("%PDF")] // trop court : il manque le tiret
    [InlineData(" %PDF-1.7")] // la signature doit être tout au début
    [InlineData("PK")] // début de ZIP incomplet
    [InlineData("Bonjour, ceci est un texte.")]
    [InlineData("{\\rtf1 document RTF}")]
    public void AutreContenu_Refuse(string content) =>
        Assert.Null(CvFileType.Detect(Encoding.UTF8.GetBytes(content)));

    [Fact]
    public void VraisFichiersGeneres_SontReconnus()
    {
        Assert.Equal(CvFileKind.Pdf, CvFileType.Detect(CvTestFiles.Pdf("Exemple")));
        Assert.Equal(CvFileKind.Docx, CvFileType.Detect(CvTestFiles.Docx("Exemple")));
    }
}

using SkillMatch.Core.Trainings;

namespace SkillMatch.Tests.Trainings;

public sealed class TrainingTests
{
    [Fact]
    public void FromPosting_Valide_ChampsNettoyesEtCleCalculee()
    {
        var posting = TrainingTestData.Posting(
            externalId: "  f-001 ",
            skill: "  JS ",
            title: "  Les   bases ",
            url: "https://example.com/formation");

        var training = Training.FromPosting("exemple", isSample: true, posting);

        Assert.NotEqual(Guid.Empty, training.Id);
        Assert.Equal("f-001", training.ExternalId);
        Assert.Equal("JS", training.Skill);
        // La clé est celle du nom du dictionnaire : « JS » est une variante de JavaScript.
        Assert.Equal("javascript", training.SkillKey);
        Assert.Equal("Les bases", training.Title);
        Assert.Equal("https://example.com/formation", training.Url);
        Assert.True(training.IsSample);
        Assert.Equal(TimeSpan.Zero, training.ImportedAt.Offset);
    }

    [Theory]
    [InlineData("javascript:alert(1)")]
    [InlineData("file:///etc/passwd")]
    [InlineData("ftp://example.com/formation")]
    [InlineData("pas une adresse")]
    [InlineData("/formations/1")]
    public void LienDangereuxOuInvalide_Refuse(string url) =>
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(url: url)));

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void SansLien_Accepte(string? url) =>
        Assert.Null(Training.FromPosting("test", false, TrainingTestData.Posting(url: url)).Url);

    [Theory]
    [InlineData(0)]
    [InlineData(-3)]
    [InlineData(Training.MaxHours + 1)]
    public void DureeHorsLimites_Refusee(int hours) =>
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(hours: hours)));

    [Theory]
    [InlineData(Training.MinHours)]
    [InlineData(Training.MaxHours)]
    public void DureeAuxLimites_Acceptee(int hours) =>
        Assert.Equal(hours, Training.FromPosting("test", false, TrainingTestData.Posting(hours: hours)).Hours);

    [Theory]
    [InlineData("  ")]
    [InlineData("---")]
    public void CompetenceVideOuSansMot_Refusee(string skill) =>
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(skill: skill)));

    [Fact]
    public void CompetenceTropLongue_Refusee() =>
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false,
                TrainingTestData.Posting(skill: new string('x', Training.MaxSkillLength + 1))));

    [Fact]
    public void TitreVideOuTropLong_Refuse()
    {
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(title: "  ")));
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false,
                TrainingTestData.Posting(title: new string('x', Training.MaxTitleLength + 1))));
    }

    [Fact]
    public void NiveauOuTypeInconnu_Refuse()
    {
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(level: (TrainingLevel)99)));
        Assert.Throws<ArgumentException>(() =>
            Training.FromPosting("test", false, TrainingTestData.Posting(type: (TrainingType)99)));
    }

    [Fact]
    public void UpdateFrom_AutreIdentifiant_Refuse()
    {
        var training = Training.FromPosting("test", false, TrainingTestData.Posting(externalId: "a"));

        Assert.Throws<ArgumentException>(() => training.UpdateFrom(TrainingTestData.Posting(externalId: "b")));
    }

    [Fact]
    public void UpdateFrom_Invalide_RienNeChange()
    {
        var training = Training.FromPosting("test", false, TrainingTestData.Posting(title: "Avant", hours: 3));

        Assert.Throws<ArgumentException>(() =>
            training.UpdateFrom(TrainingTestData.Posting(title: "Après", hours: 0)));

        Assert.Equal("Avant", training.Title);
        Assert.Equal(3, training.Hours);
    }

    [Fact]
    public void OrdreDAffichage_NiveauPuisDureePuisTitre()
    {
        Training Make(string id, string title, TrainingLevel level, int hours) =>
            Training.FromPosting("test", false,
                TrainingTestData.Posting(externalId: id, title: title, level: level, hours: hours));

        var ordered = Training.InDisplayOrder(
        [
            Make("1", "Avancé", TrainingLevel.Avance, 1),
            Make("2", "Zeta", TrainingLevel.Debutant, 3),
            Make("3", "Intermédiaire", TrainingLevel.Intermediaire, 2),
            Make("4", "alpha", TrainingLevel.Debutant, 3),
            Make("5", "Court", TrainingLevel.Debutant, 1),
        ]);

        // Débutant d'abord ; à niveau égal la plus courte ; à durée égale le
        // titre, sans tenir compte des majuscules.
        Assert.Equal(
            new[] { "Court", "alpha", "Zeta", "Intermédiaire", "Avancé" },
            ordered.Select(t => t.Title));
    }

    [Fact]
    public void Codes_AllerRetour()
    {
        foreach (var level in Enum.GetValues<TrainingLevel>())
        {
            Assert.Equal(level, TrainingCodes.ToLevel(TrainingCodes.ToCode(level)));
            Assert.True(TrainingCodes.ToCode(level).Length <= TrainingCodes.MaxCodeLength);
        }

        foreach (var type in Enum.GetValues<TrainingType>())
        {
            Assert.Equal(type, TrainingCodes.ToType(TrainingCodes.ToCode(type)));
            Assert.True(TrainingCodes.ToCode(type).Length <= TrainingCodes.MaxCodeLength);
        }
    }
}

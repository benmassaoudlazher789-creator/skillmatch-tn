using SkillMatch.Core.Jobs;

namespace SkillMatch.Tests.Jobs;

public sealed class JobTests
{
    [Fact]
    public void FromPosting_Valide_ChampsNettoyes()
    {
        var posting = JobTestData.Posting(
            externalId: "  test-001 ",
            title: "  Stage   Flutter ",
            publishedAt: new DateTimeOffset(2026, 10, 1, 10, 0, 0, TimeSpan.FromHours(1)));

        var job = Job.FromPosting("exemple", isSample: true, posting);

        Assert.NotEqual(Guid.Empty, job.Id);
        Assert.Equal("test-001", job.ExternalId);
        Assert.Equal("Stage Flutter", job.Title);
        Assert.True(job.IsSample);
        // Toujours en UTC : 10 h à UTC+1 = 9 h UTC.
        Assert.Equal(TimeSpan.Zero, job.PublishedAt.Offset);
        Assert.Equal(9, job.PublishedAt.Hour);
        Assert.Equal(3, job.Skills.Count);
        Assert.Equal(2, job.Skills.Count(s => s.Importance == SkillImportance.Required));
    }

    [Theory]
    [InlineData("javascript:alert(1)")]
    [InlineData("file:///etc/passwd")]
    [InlineData("ftp://example.com/offre")]
    [InlineData("pas une adresse")]
    [InlineData("/offres/1")]
    public void LienDangereuxOuInvalide_Refuse(string url) =>
        Assert.Throws<ArgumentException>(() => Job.FromPosting("test", false, JobTestData.Posting(url: url)));

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void SansLien_Accepte(string? url) =>
        Assert.Null(Job.FromPosting("test", false, JobTestData.Posting(url: url)).Url);

    [Fact]
    public void TitreVideOuTropLong_Refuse()
    {
        Assert.Throws<ArgumentException>(() => Job.FromPosting("test", false, JobTestData.Posting(title: "  ")));
        Assert.Throws<ArgumentException>(() =>
            Job.FromPosting("test", false, JobTestData.Posting(title: new string('x', Job.MaxTitleLength + 1))));
    }

    [Fact]
    public void SansCompetence_Refuse() =>
        Assert.Throws<ArgumentException>(() =>
            Job.FromPosting("test", false, JobTestData.Posting(required: [], preferred: [])));

    [Fact]
    public void CompetenceTropLongue_Refusee() =>
        Assert.Throws<ArgumentException>(() =>
            Job.FromPosting("test", false, JobTestData.Posting(required: [new string('x', JobSkill.MaxNameLength + 1)])));

    [Theory]
    // Même compétence à la fois requise et souhaitée.
    [InlineData("Flutter", "Flutter")]
    // Même compétence écrite autrement : majuscules, ou variante du dictionnaire.
    [InlineData("Flutter", "flutter")]
    [InlineData("JavaScript", "JS")]
    public void CompetenceEnDouble_Refusee(string required, string preferred) =>
        Assert.Throws<ArgumentException>(() =>
            Job.FromPosting("test", false, JobTestData.Posting(required: [required], preferred: [preferred])));

    [Fact]
    public void TypeInconnu_Refuse() =>
        Assert.Throws<ArgumentException>(() =>
            Job.FromPosting("test", false, JobTestData.Posting(type: (JobType)42)));

    [Fact]
    public void UpdateFrom_MetAJourLesCompetences()
    {
        var job = JobTestData.Job(required: ["Flutter", "Dart"], preferred: ["Git"]);

        // Dart passe en souhaitée, Git disparaît, Firebase arrive.
        job.UpdateFrom(JobTestData.Posting(required: ["Flutter", "Firebase"], preferred: ["Dart"]));

        var skills = job.Skills.ToDictionary(s => s.Name, s => s.Importance);
        Assert.Equal(3, skills.Count);
        Assert.Equal(SkillImportance.Required, skills["Flutter"]);
        Assert.Equal(SkillImportance.Required, skills["Firebase"]);
        Assert.Equal(SkillImportance.Preferred, skills["Dart"]);
        Assert.False(skills.ContainsKey("Git"));
    }

    [Fact]
    public void UpdateFrom_Invalide_OffreInchangee()
    {
        var job = JobTestData.Job();
        var title = job.Title;

        Assert.Throws<ArgumentException>(() =>
            job.UpdateFrom(JobTestData.Posting(title: "Nouveau titre", url: "javascript:alert(1)")));

        // Tout est contrôlé avant la moindre modification.
        Assert.Equal(title, job.Title);
        Assert.Equal(3, job.Skills.Count);
    }

    [Fact]
    public void UpdateFrom_AutreIdentifiantExterne_Refuse()
    {
        var job = JobTestData.Job(externalId: "test-001");

        Assert.Throws<ArgumentException>(() => job.UpdateFrom(JobTestData.Posting(externalId: "test-002")));
    }

    [Theory]
    [InlineData(JobType.Stage, "stage")]
    [InlineData(JobType.Pfe, "pfe")]
    [InlineData(JobType.Emploi, "emploi")]
    public void CodesDesTypes_AllerRetour(JobType type, string code)
    {
        Assert.Equal(code, JobCodes.ToCode(type));
        Assert.Equal(type, JobCodes.ToJobType(code));
    }
}

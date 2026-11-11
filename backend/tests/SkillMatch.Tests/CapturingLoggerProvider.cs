using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;

namespace SkillMatch.Tests;

/// <summary>
/// Garde en mémoire chaque message écrit dans les journaux, pour vérifier
/// qu'aucune donnée du candidat n'y apparaît.
/// (Même principe que la copie privée de CvEndpointsTests, partagée ici.)
/// </summary>
public sealed class CapturingLoggerProvider : ILoggerProvider
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

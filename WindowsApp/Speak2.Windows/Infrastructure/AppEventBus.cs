using System.Collections.Concurrent;

namespace Speak2.Windows.Infrastructure;

/// <summary>
/// NotificationCenter replacement for WinUI shell events.
/// </summary>
public sealed class AppEventBus
{
    private readonly ConcurrentDictionary<string, List<Action<object?>>> _subscriptions = new();

    public IDisposable Subscribe(string eventName, Action<object?> handler)
    {
        var handlers = _subscriptions.GetOrAdd(eventName, _ => new List<Action<object?>>());
        lock (handlers)
        {
            handlers.Add(handler);
        }

        return new Subscription(() =>
        {
            lock (handlers)
            {
                handlers.Remove(handler);
            }
        });
    }

    public void Publish(string eventName, object? payload = null)
    {
        if (!_subscriptions.TryGetValue(eventName, out var handlers))
        {
            return;
        }

        List<Action<object?>> snapshot;
        lock (handlers)
        {
            snapshot = handlers.ToList();
        }

        foreach (var handler in snapshot)
        {
            handler(payload);
        }
    }

    private sealed class Subscription(Action onDispose) : IDisposable
    {
        public void Dispose() => onDispose();
    }
}

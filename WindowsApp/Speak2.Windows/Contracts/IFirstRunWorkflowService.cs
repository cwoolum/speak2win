namespace Speak2.Windows.Contracts;

public interface IFirstRunWorkflowService
{
    Task RunAsync(CancellationToken cancellationToken = default);
}

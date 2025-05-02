using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace ImportManager
{
    public class ImportTaskDaemon : BackgroundService
    {
        private readonly ILogger<ImportTaskDaemon> _logger;

        public ImportTaskDaemon(ILogger<ImportTaskDaemon> logger)
        {
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ImportTaskDaemon is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Processing tasks at: {time}", DateTimeOffset.Now);

                // Simulate work
                await Task.Delay(1000, stoppingToken);
            }

            _logger.LogInformation("ImportTaskDaemon is stopping.");
        }
    }
}
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SharedLibrary.Data;
using SharedLibrary.Models;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ImportManager.Services;

namespace ImportManager
{
    public class ImportTaskDaemon : BackgroundService
    {
        private readonly ILogger<ImportTaskDaemon> _logger;
        private readonly IServiceProvider _serviceProvider;
        private readonly ImportTaskService _importTaskService;

        public ImportTaskDaemon(
            ILogger<ImportTaskDaemon> logger, 
            IServiceProvider serviceProvider,
            ImportTaskService importTaskService)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
            _importTaskService = importTaskService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                _importTaskService.ProcessImportTask(_serviceProvider, _logger, stoppingToken);

                // Wait before polling again
                await Task.Delay(5000, stoppingToken);
            }
        }
    }
}

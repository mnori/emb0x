using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SharedLibrary.Data;
using SharedLibrary.Models;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace ImportManager
{
    public class ImportTaskDaemon : BackgroundService
    {
        private readonly ILogger<ImportTaskDaemon> _logger;
        private readonly IServiceProvider _serviceProvider;

        public ImportTaskDaemon(ILogger<ImportTaskDaemon> logger, IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ImportTaskDaemon is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Polling for tasks at: {time}", DateTimeOffset.Now);

                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var dbContext = scope.ServiceProvider.GetRequiredService<Emb0xDatabaseContext>();

                        // Retrieve the most recent ImportTask row
                        var importTask = await dbContext.ImportTask
                            .OrderByDescending(t => t.Created)
                            .FirstOrDefaultAsync(stoppingToken);

                        if (importTask != null)
                        {
                            _logger.LogInformation("Processing ImportTask: {Id}, Description: {Description}", importTask.Id, importTask.Description);

                            // Perform actions based on the ImportTask row
                            // Example: Mark the task as started
                            importTask.Started = DateTime.UtcNow;
                            dbContext.ImportTask.Update(importTask);
                            await dbContext.SaveChangesAsync(stoppingToken);

                            // Simulate processing
                            await Task.Delay(2000, stoppingToken);

                            // Mark the task as completed
                            importTask.Completed = DateTime.UtcNow;
                            dbContext.ImportTask.Update(importTask);
                            await dbContext.SaveChangesAsync(stoppingToken);

                            _logger.LogInformation("Completed ImportTask: {Id}", importTask.Id);
                        }
                        else
                        {
                            _logger.LogInformation("No tasks found.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "An error occurred while processing tasks.");
                }

                // Wait before polling again
                await Task.Delay(5000, stoppingToken);
            }

            _logger.LogInformation("ImportTaskDaemon is stopping.");
        }
    }
}

// using Microsoft.Extensions.Hosting;
// using Microsoft.Extensions.Logging;
// using System;
// using System.Threading;
// using System.Threading.Tasks;

// namespace ImportManager
// {
//     public class ImportTaskDaemon : BackgroundService
//     {
//         private readonly ILogger<ImportTaskDaemon> _logger;

//         public ImportTaskDaemon(ILogger<ImportTaskDaemon> logger)
//         {
//             _logger = logger;
//         }

//         protected override async Task ExecuteAsync(CancellationToken stoppingToken)
//         {
//             _logger.LogInformation("ImportTaskDaemon is starting.");

//             while (!stoppingToken.IsCancellationRequested)
//             {
//                 _logger.LogInformation("Processing tasks at: {time}", DateTimeOffset.Now);

//                 // Simulate work
//                 await Task.Delay(1000, stoppingToken);
//             }

//             _logger.LogInformation("ImportTaskDaemon is stopping.");
//         }
//     }
// }
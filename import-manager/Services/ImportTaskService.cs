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
    public class ImportTaskService {

        public async void ProcessImportTask(IServiceProvider serviceProvider, ILogger<ImportTaskDaemon> logger, CancellationToken stoppingToken) {
            // Process the import task here
            // This is just a placeholder implementation
            Console.WriteLine($"Processing import task");

            try
                {
                    using (var scope = serviceProvider.CreateScope())
                    {
                        var dbContext = scope.ServiceProvider.GetRequiredService<Emb0xDatabaseContext>();

                        // Retrieve the most recent ImportTask row
                        var importTask = await dbContext.ImportTask
                            .OrderByDescending(t => t.Created)
                            .Where(t => t.Completed == null && t.Failed == null)
                            .FirstOrDefaultAsync(stoppingToken);

                        if (importTask != null)
                        {
                            logger.LogInformation("Processing ImportTask: {Id}, Description: {Description}", importTask.Id, importTask.Description);

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

                            logger.LogInformation("Completed ImportTask: {Id}", importTask.Id);
                        }
                        else
                        {
                            logger.LogInformation("No tasks found.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "An error occurred while processing tasks.");
                }

        }

    }
}
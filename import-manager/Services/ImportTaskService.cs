using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SharedLibrary.Data;
using SharedLibrary.Models;
using System;
using System.Diagnostics;
using System.IO;
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
                            ProcessUpload(importTask);

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

        public void ProcessUpload(ImportTask importTask) {
            // Process the upload here
            // This is just a placeholder implementation
            Console.WriteLine($"-- Processing upload for task {importTask.Id} in {Settings.UploadPath} --");

            var filePath = Path.Combine(Settings.UploadPath, importTask.Id + ".upload");
            ProcessFile(filePath, importTask.Id);
        }

        private void ProcessFile(string filePath, string id)
        {
            if (IsAudioFile(filePath)) {
                Console.WriteLine($"-- File {filePath} is an audio file --");

                // Convert the file to FLAC (if needed) and upload to MinIO (same shit as S3 but local)
                string bucketName = "audio-files";
                string keyName = id+".audio";

                // surely this should be autowired or whatever the c# equivalent is
                var minioService = new MinioService();
                minioService.UploadFileAsync(bucketName, keyName, filePath).Wait();

            } else {
                Console.WriteLine($"-- File {filePath} is NOT an audio file --");
                // Is it an archive? If so, unzip it to a temp directory.
                // convert the audio files within to flac. By using ffmpeg for each one.                
                // Then recursively process each file in the temp directory with the ProcessFile method.
            }
        }

        public static bool IsAudioFile(string filePath)
        {
            if (!File.Exists(filePath))
            {
                throw new FileNotFoundException($"File not found: {filePath}");
            }

            try
            {
                // Prepare the ffprobe process
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "ffprobe", // Ensure ffprobe is in the PATH or provide the full path
                        Arguments = $"-v error -show_entries stream=codec_type -of csv=p=0 \"{filePath}\"",
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };

                // Start the process
                process.Start();

                // Read the output
                string output = process.StandardOutput.ReadToEnd();
                process.WaitForExit();

                // Check if the output contains "audio"
                return output.Contains("audio");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred while checking the file: {ex.Message}");
                return false;
            }
        }

    }
}
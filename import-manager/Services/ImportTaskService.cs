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

        public async void ProcessImportTask(
            IServiceProvider serviceProvider, 
            ILogger<ImportTaskDaemon> logger, 
            CancellationToken stoppingToken) {

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
                            ProcessUpload(importTask, dbContext);

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

        public void ProcessUpload(ImportTask importTask, Emb0xDatabaseContext dbContext) {
            // Process the upload here
            // This is just a placeholder implementation
            Console.WriteLine($"-- Processing upload for task {importTask.Id} in {Settings.UploadPath} --");

            var filePath = Path.Combine(Settings.UploadPath, importTask.Id + ".upload");
            ProcessFile(filePath, importTask.Id, dbContext);
        }

        private void ProcessFile(string originalFilepath, string id, Emb0xDatabaseContext dbContext)
        {
            // Check if the file is an audio file using ffprobe
            // If it is, convert it to FLAC using ffmpeg and upload to MinIO (or S3)
            // If it is not, check if it is an archive. If so, unzip it to a temp directory.
            // Convert the audio files within to flac. By using ffmpeg for each one.
            // Then recursively process each file in the temp directory with the ProcessFile method.

            Console.WriteLine($"-- Processing file {originalFilepath} --");

            // Check if the file is an audio file
            if (IsAudioFile(originalFilepath)) {
                Console.WriteLine($"-- File {originalFilepath} is an audio file --");

                // Convert the file to FLAC (if needed) and upload to MinIO (same shit as S3 but local)
                string bucketName = "audio-files";
                string keyName = id+".flac";

                var flacFilepath = originalFilepath+".flac";
                ConvertToFlac(originalFilepath, flacFilepath);

                // now save to the database, use the dbContext
                // Save a new row into the Track table
                // Getting the artist and track name is gnarly.
                // Perhaps it can be done though, universally, through
                // ffmpeg.
                var newTrack = new Track
                {
                    Id = id, // Generate a unique ID
                    ArtistName = "Unnamed Artist", 
                    TrackName = "Unnamed Track",
                    CreatedOn = DateTime.UtcNow
                };

                dbContext.Track.Add(newTrack); // Add the new track to the DbContext
                dbContext.SaveChanges(); // Save changes to the database

                Console.WriteLine($"-- New track saved to database with ID: {newTrack.Id} --");

                // surely this should be autowired or whatever the c# equivalent is
                var minioService = new MinioService();
                minioService.UploadFileAsync(bucketName, keyName, flacFilepath).Wait();

            } else {
                Console.WriteLine($"-- File {originalFilepath} is NOT an audio file --");
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

        public void ConvertToFlac(string inputFilePath, string outputFilePath)
        {
            if (!File.Exists(inputFilePath))
            {
                throw new FileNotFoundException($"Input file not found: {inputFilePath}");
            }

            try
            {
                // Prepare the ffmpeg process
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "ffmpeg", // Ensure ffmpeg is in the PATH or provide the full path
                        Arguments = $"-i \"{inputFilePath}\" -y \"{outputFilePath}\"", // -y overwrites the output file if it exists
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };

                // Start the process
                process.Start();

                // Read the output and error streams (optional, for debugging)
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();

                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    throw new Exception($"ffmpeg failed with exit code {process.ExitCode}: {error}");
                }

                Console.WriteLine($"File converted to FLAC: {outputFilePath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred while converting the file to FLAC: {ex.Message}");
                throw;
            }
        }

    }
}
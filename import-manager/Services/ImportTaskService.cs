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
using System.IO.Compression;
using SharpCompress.Archives;
using SharpCompress.Common;
using ImportManager.Services;
using Minio;

namespace ImportManager.Services
{
    public class ImportTaskService {

        private readonly HashSet<string> _processedChecksums = new HashSet<string>();

        private readonly StorageService _storage;
        public ImportTaskService(StorageService storage)
        {
            _storage = storage;
        }
        
        public async void ProcessImportTask(
            IServiceProvider serviceProvider, 
            ILogger<ImportTaskDaemon> logger, 
            CancellationToken stoppingToken) {

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
                            // logger.LogInformation("Processing ImportTask: {Id}, Description: {Description}", importTask.Id, importTask.Description);

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

                            // logger.LogInformation("Completed ImportTask: {Id}", importTask.Id);
                        }
                        else
                        {
                            // logger.LogInformation("No tasks found.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    // logger.LogError(ex, "An error occurred while processing tasks.");
                }

        }

        public void ProcessUpload(ImportTask importTask, Emb0xDatabaseContext dbContext) {
            // Process the upload here
            // This is just a placeholder implementation
            // Console.WriteLine($"-- Processing upload for task {importTask.Id} in {Settings.UploadPath} --");

            var filePath = Path.Combine(Settings.UploadPath, importTask.Id + ".upload");
            ProcessFile(filePath, dbContext);
        }

        private void ProcessFile(string originalFilepath, Emb0xDatabaseContext dbContext)
        {

            // Calculate the checksum of the file
            string checksum = CalculateChecksum(originalFilepath);

            // Check if the file has already been processed
            if (_processedChecksums.Contains(checksum))
            {
                Console.WriteLine($"-- Skipping duplicate file: {originalFilepath} (Checksum: {checksum}) --");
                return;
            }

            _processedChecksums.Add(checksum);

            Console.WriteLine($"-- Processing file {originalFilepath} --");


            // Check if the file is an audio file using ffprobe
            // If it is, convert it to FLAC using ffmpeg and upload to MinIO (or S3)
            // If it is not, check if it is an archive. If so, unzip it to a temp directory.
            // Convert the audio files within to flac. By using ffmpeg for each one.
            // Then recursively process each file in the temp directory with the ProcessFile method.

            // Console.WriteLine($"-- Processing file {originalFilepath} --");

            // Generate a new unique ID for the file.
            var id = Guid.NewGuid().ToString();

            // Check if the file is an audio file
            if (IsAudioFile(originalFilepath)) {
                Console.WriteLine($"-- File {originalFilepath} is an audio file --");
                ProcessAudioFile(originalFilepath, id, dbContext);

            } else {
                Console.WriteLine($"-- File {originalFilepath} isn't audio --");
                string tempDirectory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());

                // Console.WriteLine($"-- Creating temporary directory: {tempDirectory} --");

                Directory.CreateDirectory(tempDirectory);

                try
                {
                    bool wasCompressedFile = UnpackCompressedFile(originalFilepath, tempDirectory);
                    if (wasCompressedFile)
                    {
                        // Console.WriteLine($"-- File {originalFilepath} was successfully unpacked --");

                        foreach (var file in Directory.GetFiles(tempDirectory, "*", SearchOption.AllDirectories))
                        {
                            Console.WriteLine($"-- Processing extracted file: {file} --");
                            ProcessFile(file, dbContext); // Recursively process extracted files
                        }
                    }
                    else
                    {
                        // Console.WriteLine($"-- File {originalFilepath} is NOT a compressed file --");
                    }
                }
                finally
                {
                    Directory.Delete(tempDirectory, true); // Clean up temporary directory
                }
            }
        }

        private string CalculateChecksum(string filePath)
        {
            using (var stream = File.OpenRead(filePath))
            {
                using (var sha256 = System.Security.Cryptography.SHA256.Create())
                {
                    byte[] hash = sha256.ComputeHash(stream);
                    return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
                }
            }
        }

        
        public bool UnpackCompressedFile(string filePath, string outputDirectory)
        {

            Console.WriteLine($"-- UnpackCompressedFile() invoked for {filePath} {outputDirectory} --");

            // Check if the file exists

            if (!File.Exists(filePath))
            {
                throw new FileNotFoundException($"File not found: {filePath}");
            }

            // Ensure the output directory exists
            Directory.CreateDirectory(outputDirectory);

            try
            {
                // Read the first few bytes of the file to determine its type
                byte[] fileHeader = new byte[4];
                using (var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
                {
                    fileStream.Read(fileHeader, 0, fileHeader.Length);
                }

                // Check the file header (magic numbers)
                if (IsZipFile(fileHeader))
                {
                    // Console.WriteLine($"-- Detected .zip file: {filePath}. Extracting... --");
                    ZipFile.ExtractToDirectory(filePath, outputDirectory);
                    return true;
                }
                else if (IsTarFile(fileHeader) || IsGzipFile(fileHeader) || Is7zFile(fileHeader) || IsRarFile(fileHeader))
                {
                    // Console.WriteLine($"-- Detected compressed file: {filePath}. Extracting... --");
                    using (var archive = ArchiveFactory.Open(filePath))
                    {
                        foreach (var entry in archive.Entries)
                        {
                            if (!entry.IsDirectory)
                            {
                                // Console.WriteLine($"-- Extracting: {entry.Key} --");
                                entry.WriteToDirectory(outputDirectory, new ExtractionOptions
                                {
                                    ExtractFullPath = true,
                                    Overwrite = true
                                });
                            }
                        }
                    }
                    return true;
                }
                else
                {
                    // Console.WriteLine($"-- File {filePath} is not a supported compressed format. Skipping... --");
                    return false;
                }
            }
            catch (Exception ex)
            {
                // Console.WriteLine($"An error occurred while unpacking the file: {ex.Message}");
                return false;
            }
        }

        private void ProcessAudioFile(string originalFilepath, string id, Emb0xDatabaseContext dbContext) {
            // Console.WriteLine($"-- File {originalFilepath} is an audio file --");

            // Convert the file to FLAC (if needed) and upload to MinIO (same shit as S3 but local)
            string bucketName = "audio-files";
            string keyName = id+".flac";

            var flacFilepath = originalFilepath+".flac";
            ConvertToFlac(originalFilepath, flacFilepath);

            string checksum = CalculateChecksum(flacFilepath);
            

            // Get metadata from the FLAC file
            var (artistName, trackTitle) = GetMetadataFromFlac(flacFilepath);

            // now save to the database, use the dbContext
            // Save a new row into the Track table
            // Getting the artist and track name is gnarly.
            // Perhaps it can be done though, universally, through
            // ffmpeg.
            var newTrack = new Track
            {
                Id = id, // Generate a unique ID
                Checksum = checksum,
                ArtistName = artistName, 
                TrackTitle = trackTitle, // todo: rename TrackName=>TrackTitle in the Track object
                CreatedOn = DateTime.UtcNow
            };

            dbContext.Track.Add(newTrack); // Add the new track to the DbContext
            dbContext.SaveChanges(); // Save changes to the database

            // Console.WriteLine($"-- New track saved to database with ID: {newTrack.Id} --");

            // surely this should be autowired or whatever the c# equivalent is
            // var minioService = new MinioService();
            // minioService.UploadFileAsync(bucketName, keyName, flacFilepath).Wait();

            await _storage.UploadFileAsync(bucketName, keyName, flacFilepath);
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
                // Console.WriteLine($"An error occurred while checking the file: {ex.Message}");
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

        public (string ArtistName, string TrackTitle) GetMetadataFromFlac(string filePath)
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
                        Arguments = $"-v error -show_entries format_tags=artist,title -of default=noprint_wrappers=1:nokey=1 \"{filePath}\"",
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

                if (process.ExitCode != 0)
                {
                    throw new Exception($"ffprobe failed with exit code {process.ExitCode}: {process.StandardError.ReadToEnd()}");
                }

                // Split the output into lines (artist and title)
                var lines = output.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);

                // Extract artist and title
                string artistName = lines.Length > 0 ? lines[0] : "Unknown Artist";
                string trackTitle = lines.Length > 1 ? lines[1] : "Unknown Title";

                return (artistName, trackTitle);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred while retrieving metadata: {ex.Message}");
                return ("Unknown Artist", "Unknown Title");
            }
        }

        private bool IsZipFile(byte[] fileHeader)
        {
            // ZIP files start with 0x50 0x4B 0x03 0x04
            return fileHeader[0] == 0x50 && fileHeader[1] == 0x4B && fileHeader[2] == 0x03 && fileHeader[3] == 0x04;
        }

        private bool IsTarFile(byte[] fileHeader)
        {
            // TAR files don't have a fixed magic number, but SharpCompress can handle them
            return false; // Let SharpCompress handle TAR detection
        }

        private bool IsGzipFile(byte[] fileHeader)
        {
            // GZIP files start with 0x1F 0x8B
            return fileHeader[0] == 0x1F && fileHeader[1] == 0x8B;
        }

        private bool Is7zFile(byte[] fileHeader)
        {
            // 7z files start with 0x37 0x7A 0xBC 0xAF
            return fileHeader[0] == 0x37 && fileHeader[1] == 0x7A && fileHeader[2] == 0xBC && fileHeader[3] == 0xAF;
        }

        private bool IsRarFile(byte[] fileHeader)
        {
            // RAR files start with 0x52 0x61 0x72 0x21
            return fileHeader[0] == 0x52 && fileHeader[1] == 0x61 && fileHeader[2] == 0x72 && fileHeader[3] == 0x21;
        }
    }
}
using Microsoft.EntityFrameworkCore;
using SharedLibrary.Data;
using Minio;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ImportManager.Services;
using Amazon;
using Amazon.S3; // added
using Amazon.Extensions.NETCore.Setup; // added

namespace ImportManager
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureServices((hostContext, services) =>
                {
                    // Create a console logger for startup messages
                    using var startupLoggerFactory = LoggerFactory.Create(logging =>
                    {
                        logging.ClearProviders();
                        logging.AddConsole();
                        logging.SetMinimumLevel(LogLevel.Information);
                        logging.AddFilter("Microsoft.EntityFrameworkCore", LogLevel.Warning);
                    });
                    var startupLogger = startupLoggerFactory.CreateLogger("Startup");
                    
                    // Storage provider selection
                    var provider = Environment.GetEnvironmentVariable("STORAGE_PROVIDER") ?? "minio";
                    if (provider.Equals("s3", StringComparison.OrdinalIgnoreCase))
                    {
                        startupLogger.LogInformation("Using S3 storage provider.");

                        // Region from env or fallback
                        var regionEnv = Environment.GetEnvironmentVariable("AWS_REGION");
                        RegionEndpoint region;
                        try
                        {
                            // prefer env if valid, else fallback
                            var regionName = string.IsNullOrWhiteSpace(regionEnv) ? "eu-central-1" : regionEnv;
                            region = RegionEndpoint.GetBySystemName(regionName);
                        }
                        catch (ArgumentException)
                        {
                            startupLogger.LogWarning("Invalid AWS_REGION '{RegionEnv}', falling back to eu-central-1.", regionEnv);
                            region = RegionEndpoint.EUCentral1;
                        }

                        // var regionName = Environment.GetEnvironmentVariable("AWS_REGION") ?? "eu-central-1";
                        // var region = RegionEndpoint.GetBySystemName(regionName);

                        // AmazonS3Client uses the default AWS credential chain:
                        // env vars (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN),
                        // shared credentials, or IAM role.
                        services.AddSingleton<IAmazonS3>(_ => new AmazonS3Client(region));
                        services.AddSingleton<StorageService, S3StorageService>();

                        // services.AddDefaultAWSOptions(hostContext.Configuration.GetAWSOptions());
                        // services.AddAWSService<IAmazonS3>();
                        // services.AddSingleton<StorageService, S3StorageService>();
                    }
                    else
                    {
                        startupLogger.LogInformation("Using Minio storage provider.");
                        var endpoint = Environment.GetEnvironmentVariable("MINIO_ENDPOINT") ?? "minio:9000";
                        var access = Environment.GetEnvironmentVariable("MINIO_ACCESS_KEY") ?? "minioadmin";
                        var secret = Environment.GetEnvironmentVariable("MINIO_SECRET_KEY") ?? "minioadmin";

                        services.AddSingleton<IMinioClient>(_ =>
                            new MinioClient()
                                .WithEndpoint(endpoint)
                                .WithCredentials(access, secret)
                                .Build());
                        services.AddSingleton<StorageService, MinioStorageService>();
                    }

                    services.AddDbContext<Emb0xDatabaseContext>(options =>
                        options.UseMySql(
                            hostContext.Configuration.GetConnectionString("Emb0xDatabaseContext"),
                            new MySqlServerVersion(new Version(8, 0, 32)))
                        .LogTo(Console.WriteLine, LogLevel.None));

                    services.AddScoped<ImportTaskService>();
                    services.AddHostedService<ImportTaskDaemon>();
                });


    }
}

using Microsoft.EntityFrameworkCore;
using SharedLibrary.Data;
using Minio;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ImportManager.Services;
using Amazon.S3; // added
using Amazon.Extensions.NETCore.Setup; // added

namespace ImportManager
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
            // // SetupStorageService();

            // builder.Services.AddSingleton<IMinioClient>(_ =>
            //     new MinioClient()
            //         .WithEndpoint(Environment.GetEnvironmentVariable("MINIO_ENDPOINT") ?? "minio:9000")
            //         .WithCredentials(Environment.GetEnvironmentVariable("MINIO_ACCESS_KEY") ?? "minioadmin",
            //                         Environment.GetEnvironmentVariable("MINIO_SECRET_KEY") ?? "minioadmin")
            //         .Build());
            // builder.Services.AddSingleton<StorageService, MinioService>();
            // builder.Services.AddSingleton<ImportTaskService>();

            // builder.Services.AddSingleton<IMinioClient>(_ =>
            //     new MinioClient().WithEndpoint("minio:9000").WithCredentials("minioadmin","minioadmin").Build());
            // builder.Services.AddSingleton<StorageService, MinioStorageService>();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging(logging =>
                {
                    logging.ClearProviders();
                    logging.AddConsole();
                    logging.AddFilter("Microsoft.EntityFrameworkCore", LogLevel.Warning);
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Storage provider selection
                    var provider = Environment.GetEnvironmentVariable("STORAGE_PROVIDER") ?? "Minio";
                    if (provider.Equals("S3", StringComparison.OrdinalIgnoreCase))
                    {
                        services.AddAWSService<Amazon.S3.IAmazonS3>();
                        services.AddSingleton<StorageService, S3StorageService>();
                    }
                    else
                    {
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

                    services.AddDefaultAWSOptions(hostContext.Configuration.GetAWSOptions());
                    services.AddAWSService<Amazon.S3.IAmazonS3>();
                });


    }
}

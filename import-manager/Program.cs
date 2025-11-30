using Microsoft.EntityFrameworkCore;
using SharedLibrary.Data;
using Minio;
using Microsoft.Extensions.Hosting;
// using Services.StorageService;
using ImportManager.Services;

namespace ImportManager
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // CreateHostBuilder(args).Build().Run();
            // // SetupStorageService();

            // builder.Services.AddSingleton<IMinioClient>(_ =>
            //     new MinioClient()
            //         .WithEndpoint(Environment.GetEnvironmentVariable("MINIO_ENDPOINT") ?? "minio:9000")
            //         .WithCredentials(Environment.GetEnvironmentVariable("MINIO_ACCESS_KEY") ?? "minioadmin",
            //                         Environment.GetEnvironmentVariable("MINIO_SECRET_KEY") ?? "minioadmin")
            //         .Build());
            // builder.Services.AddSingleton<StorageService, MinioService>();
            // builder.Services.AddSingleton<ImportTaskService>();

            builder.Services.AddSingleton<IMinioClient>(_ =>
                new MinioClient().WithEndpoint("minio:9000").WithCredentials("minioadmin","minioadmin").Build());
            builder.Services.AddSingleton<StorageService, MinioService>();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging(logging =>
                {
                    logging.ClearProviders();
                    logging.AddConsole();
                    logging.AddFilter("Microsoft.EntityFrameworkCore", LogLevel.Warning); // Suppress SQL logs
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Add DbContext with MySQL configuration
                    services.AddDbContext<Emb0xDatabaseContext>(options =>
                        options.UseMySql(
                            hostContext.Configuration.GetConnectionString("Emb0xDatabaseContext"),
                            new MySqlServerVersion(new Version(8, 0, 32)) // Replace with your MySQL version
                        )
                        .LogTo(Console.WriteLine, LogLevel.None)); // Disable SQL logging

                    services.AddScoped<ImportTaskService>();

                    // Add your background service or other dependencies here
                    services.AddHostedService<ImportTaskDaemon>();
                });

        // public void SetupStorageService()
        // {
        //     var provider = Environment.GetEnvironmentVariable("STORAGE_PROVIDER") ?? "Minio";

        //     if (provider.Equals("S3", StringComparison.OrdinalIgnoreCase))
        //     {
        //         builder.Services.AddAWSService<IAmazonS3>();
        //         builder.Services.AddSingleton<StorageService, S3StorageService>();
        //     }
        //     else
        //     {
        //         var endpoint = Environment.GetEnvironmentVariable("MINIO_ENDPOINT") ?? "minio:9000";
        //         var access = Environment.GetEnvironmentVariable("MINIO_ACCESS_KEY") ?? "admin";
        //         var secret = Environment.GetEnvironmentVariable("MINIO_SECRET_KEY") ?? "confidentcats4eva";

        //         builder.Services.AddSingleton<IMinioClient>(_ =>
        //             new MinioClient().WithEndpoint(endpoint).WithCredentials(access, secret).Build());
        //         builder.Services.AddSingleton<StorageService, MinioStorageService>();
        //     }
        // }

    }
}

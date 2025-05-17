using Microsoft.EntityFrameworkCore;
using SharedLibrary.Data;

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
    }
}

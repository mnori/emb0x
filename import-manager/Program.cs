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
                .ConfigureServices((hostContext, services) =>
                {
                    // Add DbContext
                    services.AddDbContext<Emb0xDatabaseContext>();

                    // Add your background service or other dependencies here
                    services.AddHostedService<ImportTaskDaemon>();
                });
    }
}

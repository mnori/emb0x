using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace SharedLibrary.Data
{
    public class Emb0xDatabaseContextFactory : IDesignTimeDbContextFactory<Emb0xDatabaseContext>
    {
        public Emb0xDatabaseContext CreateDbContext(string[] args)
        {
            // Build configuration
            IConfigurationRoot configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .Build();

            // Get the connection string
            var connectionString = configuration.GetConnectionString("Emb0xDatabaseContext");

            // Configure DbContextOptions
            var optionsBuilder = new DbContextOptionsBuilder<Emb0xDatabaseContext>();
            optionsBuilder.UseMySql(
                connectionString,
                new MySqlServerVersion(new Version(8, 0, 32)),
                options => options.EnableRetryOnFailure()
            );

            return new Emb0xDatabaseContext(optionsBuilder.Options);
        }
    }
}
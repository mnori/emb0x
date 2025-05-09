using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SharedLibrary.Models;

namespace SharedLibrary.Data
{
    public class Emb0xDatabaseContext : DbContext
    {
        public Emb0xDatabaseContext (DbContextOptions<Emb0xDatabaseContext> options)
            : base(options)
        {
        }
        
        public DbSet<ImportTask> ImportTask { get; set; } = default!; 
        public DbSet<Track> Track { get; set; } = default!;
        public DbSet<Movie> Movie { get; set; } = default!;
    }
    
}

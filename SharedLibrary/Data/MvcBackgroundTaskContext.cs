using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SharedLibrary.Models;

namespace SharedLibrary.Data
{
    public class MvcBackgroundTaskContext : DbContext
    {
        public MvcBackgroundTaskContext (DbContextOptions<MvcBackgroundTaskContext> options)
            : base(options)
        {
        }

        public DbSet<BackgroundTask> BackgroundTask { get; set; } = default!;
    }
}

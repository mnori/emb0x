using System.Diagnostics;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MvcMovie.Data;
using MvcMovie.Models;
var builder = WebApplication.CreateBuilder(args);

var projectRoot = Path.GetFullPath(AppContext.BaseDirectory);
Directory.SetCurrentDirectory(projectRoot);

System.Diagnostics.Debug.WriteLine($"## Current Directory: {Directory.GetCurrentDirectory()}");

// this is version of Pomelo.EntityFrameworkCore.MySql
// var connectionString = builder.Configuration.GetConnectionString("ConnectionStrings__MvcMovieContext");
var connectionString = builder.Configuration.GetConnectionString("MvcMovieContext") ??
                       Environment.GetEnvironmentVariable("ConnectionStrings__MvcMovieContext");
System.Diagnostics.Debug.WriteLine($"## ConnectionString {connectionString}");
// if (builder.Environment.IsDevelopment())
// {
    System.Diagnostics.Debug.WriteLine("## DEVELOPMENT ENVIRONMENT");
    if (string.IsNullOrEmpty(connectionString))
    {
        throw new InvalidOperationException("The connection string 'MvcMovieContext' is not configured.");
    }

    builder.Services.AddDbContext<MvcMovieContext>(options =>
        options.UseMySql(
            connectionString,
            new MySqlServerVersion(new Version(8, 0, 32)) // Adjust MySQL version as needed
        ));

    // builder.Services.AddDbContext<MvcMovieContext>(options =>
    // options.UseMySql(
    //     connectionString,
    //     new MySqlServerVersion(new Version(8, 0, 32)) // Adjust MySQL version as needed
    // ));
    
    // builder.Services.AddDbContext<MvcMovieContext>(options =>
    //     options.UseMySql(
    //         connectionString,
    //         mysqlVersion // Specify the MySQL version
    //     )
    // );
    // builder.Services.AddDbContext<MvcMovieContext>(options =>
    //     options.UseSqlite(builder.Configuration.GetConnectionString("MvcMovieContext")));
// }
// else
// {
//     System.Diagnostics.Debug.WriteLine("## NOT DEVELOPMENT ENVIRONMENT");
//     builder.Services.AddDbContext<MvcMovieContext>(options =>
//         options.UseSqlServer(builder.Configuration.GetConnectionString("ProductionMvcMovieContext")));
// }


// builder.Services.AddDbContext<MvcMovieContext>(options =>
//     options.UseSqlite(builder.Configuration.GetConnectionString("MvcMovieContext") ?? throw new InvalidOperationException("Connection string 'MvcMovieContext' not found.")));

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var context = services.GetRequiredService<MvcMovieContext>();
    context.Database.EnsureCreated();
    SeedData.Initialize(services);
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.Urls.Add("http://0.0.0.0:5000");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=HomeController}/{action=Index}/{id?}")
    .WithStaticAssets();

app.Run();

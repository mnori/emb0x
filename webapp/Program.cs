using Microsoft.EntityFrameworkCore;
using SharedLibrary.Models;
using SharedLibrary.Data;
using Microsoft.AspNetCore.Http.Features;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to allow larger request body sizes
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 1073741824; // 1GB in bytes
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 1073741824; // 1GB
    // options.MultipartBodyTemporaryFileDirectory = "/tmp";
});

var projectRoot = Path.GetFullPath(AppContext.BaseDirectory);
Directory.SetCurrentDirectory(projectRoot);

System.Diagnostics.Debug.WriteLine($"## Current Directory: {Directory.GetCurrentDirectory()}");

var connectionString = builder.Configuration.GetConnectionString("Emb0xDatabaseContext") ??
                       Environment.GetEnvironmentVariable("ConnectionStrings__Emb0xDatabaseContext");

System.Diagnostics.Debug.WriteLine($"## ConnectionString {connectionString}");
System.Diagnostics.Debug.WriteLine("## DEVELOPMENT ENVIRONMENT");
if (string.IsNullOrEmpty(connectionString))
{
    throw new InvalidOperationException("The connection string 'MvcMovieContext' is not configured.");
}

var mysqlVersion = new MySqlServerVersion(new Version(8, 0, 32));

builder.Services.AddDbContext<Emb0xDatabaseContext>(options =>
    options.UseMySql(connectionString, mysqlVersion));

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var context = services.GetRequiredService<Emb0xDatabaseContext>();
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

app.UseStaticFiles();

app.Urls.Add("http://0.0.0.0:5000");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=HomeController}/{action=Index}/{id?}");

app.Run();

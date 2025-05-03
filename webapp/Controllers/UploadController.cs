using Microsoft.AspNetCore.Mvc;
using SharedLibrary.Data;
using SharedLibrary.Models;
using System.Text.Encodings.Web;

namespace webapp.Controllers;

public class UploadController : Controller
{

    private readonly Emb0xDatabaseContext _context;

    public UploadController(Emb0xDatabaseContext context)
    {
        _context = context;
    }

    [HttpGet]
    public IActionResult Index()
    {
        return View(); // serves the Upload/Index.cshtml view
    }

    [HttpPost]
    [Route("Upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest("No file was uploaded.");
        }

        try
        {
            // Generate a unique file name to avoid conflicts
            var id = Guid.NewGuid().ToString();
            var fileName = id + ".upload";
            var filePath = Path.Combine(Settings.UploadPath, fileName);

            // Save the file to the shared volume under its random name
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var importTask = new ImportTask
            {
                Id = "123", // Use the original file name as the task name
                Type = "IMPORT", // e.g. IMPORT
                Description = file.FileName, // e.g. the original filename
                Created = DateTime.UtcNow
            };
            // Create a new ImportTask entity
            // var importTask = new ImportTask
            // {
            //     TaskName = file.FileName, // Use the original file name as the task name
            //     Data = filePath,         // Store the file path in the Data field
            //     IsProcessed = false,     // Mark the task as not processed
            //     CreatedAt = DateTime.UtcNow
            // };

            // Add the ImportTask to the database
            _context.ImportTask.Add(importTask);
            await _context.SaveChangesAsync();

            return Ok(new { FileName = fileName, FilePath = filePath });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Internal server error: {ex.Message}");
        }
    }
}
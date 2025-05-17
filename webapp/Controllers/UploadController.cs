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
            // Generate a unique file name to avoid conflicts. This
            // is the ID of the one upload file at this point.
            // Not the same as the ID of the processed result.
            var id = Guid.NewGuid().ToString();
            var fileName = id + ".upload";
            var filePath = Path.Combine(Settings.UploadPath, fileName);

            // Save the file to the shared volume under its random name
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Add the ImportTask to the database
            var importTask = new ImportTask
            {
                Id = id,
                Type = "IMPORT",
                Description = file.FileName,
                Created = DateTime.UtcNow
            };
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
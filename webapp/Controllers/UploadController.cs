using Microsoft.AspNetCore.Mvc;
using System.Text.Encodings.Web;

namespace MvcMovie.Controllers;

public class UploadController : Controller
{
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

            return Ok(new { FileName = fileName, FilePath = filePath });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Internal server error: {ex.Message}");
        }
    }
}
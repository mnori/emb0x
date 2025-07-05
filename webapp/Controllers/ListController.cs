using Microsoft.AspNetCore.Mvc;
using SharedLibrary.Data;
using System.Linq;

namespace webapp.Controllers
{
    public class ListController : Controller
    {
        private readonly Emb0xDatabaseContext _context;

        public ListController(Emb0xDatabaseContext context)
        {
            _context = context;
        }

        [HttpGet]
        [Route("songs")]
        public IActionResult GetAllSongs()
        {
            // MinIO configuration
            string minioEndpoint = "http://localhost:9000";
            string bucketName = "audio-files";

            // Query the Track table
            var songs = _context.Track
                .Select(track => new
                {
                    ArtistName = track.ArtistName,
                    TrackTitle = track.TrackTitle,
                    Link = $"{minioEndpoint}/{bucketName}/{track.Id}.flac"
                })
                .ToList();

            // Pass the songs to the view
            return View(songs);
        }
    }
}
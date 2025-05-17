using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedLibrary.Models {

    // This will be a lot more complex in the future, but for now it's just a placeholder to test the import process

    public class Track
    {
        public string Id { get; set; } // UUID. Points to a place on S3 or similar
        public string Checksum { get; set; }
        public string ArtistName { get; set; }
        public string TrackTitle { get; set; }
        public DateTime CreatedOn { get; set; }
    }
}
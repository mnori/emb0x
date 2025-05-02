using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedLibrary.Models;

public class ImportTask
{
    public int Id { get; set; } // UUID - matches the upload filename on the disk
    public string Type { get; set; } // e.g. IMPORT
    
    public string Description { get; set; } // e.g. the original filename

    public DateTime Created { get; set; }
    public DateTime? Started { get; set; }
    public DateTime? Completed { get; set; }
    public DateTime? Failed { get; set; }
    
    public string? FailedReason { get; set; } // e.g. a nice detailed stack trace
}
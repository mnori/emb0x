using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedLibrary.Models;

public class BackgroundTask
{
    public int Id { get; set; } // UUID - matches the upload filename on the disk
    public string? Type { get; set; } // e.g. IMPORT
    
    public DateTime Created { get; set; }
    public DateTime Started { get; set; }
    public DateTime Completed { get; set; }
    
}
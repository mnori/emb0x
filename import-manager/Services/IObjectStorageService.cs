namespace ImportManager.Services
{
    public interface IObjectStorageService
    {
        Task UploadFileAsync(string bucketName, string objectName, string filePath, CancellationToken ct = default);
    }
}

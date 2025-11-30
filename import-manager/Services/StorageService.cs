
namespace ImportManager.Services
{

    using System.Threading;
    using System.Threading.Tasks;

    public abstract class StorageService
    {
        public abstract Task UploadFileAsync(string bucketName, string objectName, string filePath, CancellationToken ct = default);
    }
}
using System;
using System.Threading;
using System.Threading.Tasks;
using Minio;
using Minio.DataModel.Args;

namespace ImportManager.Services
{
    public class MinioStorageService : StorageService
    {
        private readonly IMinioClient _client;

        public MinioStorageService(IMinioClient client)
        {
            _client = client;
        }

        public override async Task UploadFileAsync(string bucketName, string objectName, string filePath, CancellationToken ct = default)
        {
            try
            {
                var exists = await _client.BucketExistsAsync(new BucketExistsArgs().WithBucket(bucketName), ct);
                if (!exists)
                {
                    await _client.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucketName), ct);
                }

                await _client.PutObjectAsync(new PutObjectArgs()
                    .WithBucket(bucketName)
                    .WithObject(objectName)
                    .WithFileName(filePath), ct);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"MinIO upload error: {ex.Message}");
                throw;
            }
        }
    }
}
using Minio;
using Minio.DataModel.Args;

namespace ImportManager.Services
{
    public class MinioStorageService : StorageService
    {
        private readonly IMinioClient _client;
        public MinioStorageService(IMinioClient client) => _client = client;

        public override async Task UploadFileAsync(string bucket, string key, string filePath, CancellationToken ct = default)
        {
            if (!await _client.BucketExistsAsync(new BucketExistsArgs().WithBucket(bucket), ct))
                await _client.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucket), ct);

            await _client.PutObjectAsync(new PutObjectArgs()
                .WithBucket(bucket).WithObject(key).WithFileName(filePath), ct);
        }
    }
}
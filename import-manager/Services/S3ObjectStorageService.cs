using Amazon.S3;
using Amazon.S3.Model;
namespace ImportManager.Services
{
    public class S3ObjectStorageService : IObjectStorageService
    {
        private readonly IAmazonS3 _s3;
        public S3ObjectStorageService(IAmazonS3 s3) => _s3 = s3;

        public async Task UploadFileAsync(string bucket, string objectName, string filePath, CancellationToken ct = default)
        {
            if (!await _s3.DoesS3BucketExistAsync(bucket))
            {
                await _s3.PutBucketAsync(new PutBucketRequest { BucketName = bucket }, ct);
            }
            await _s3.PutObjectAsync(new PutObjectRequest {
                BucketName = bucket,
                Key = objectName,
                FilePath = filePath
            }, ct);
        }
    }
}

using System.Threading;
using System.Threading.Tasks;
using Amazon.S3;
using Amazon.S3.Model;

namespace ImportManager.Services
{
    public class S3StorageService : StorageService
    {
        private readonly IAmazonS3 _s3;

        public S3StorageService(IAmazonS3 s3)
        {
            _s3 = s3;
        }

        public override async Task UploadFileAsync(string bucketName, string objectName, string filePath, CancellationToken ct = default)
        {
            // Ensure bucket exists (safe for most regions; adjust for restricted regions if needed)
            var exists = await _s3.DoesS3BucketExistAsync(bucketName);
            if (!exists)
            {
                await _s3.PutBucketAsync(new PutBucketRequest { BucketName = bucketName }, ct);
            }

            var put = new PutObjectRequest
            {
                BucketName = bucketName,
                Key = objectName,
                FilePath = filePath
            };
            await _s3.PutObjectAsync(put, ct);
        }
    }
}
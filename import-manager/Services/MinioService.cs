using Minio;
using Minio.DataModel;
using Minio.DataModel.Args;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ImportManager
{
    public class MinioService
    {
        private readonly IMinioClient _minioClient;

        public MinioService()
        {
            // Configure MinIO client
            _minioClient = new MinioClient()
                .WithEndpoint("minio", 9000) // Use the service name "minio" as the endpoint
                .WithCredentials("admin", "confidentcats4eva")
                .Build();
        }

       public async Task UploadFileAsync(string bucketName, string objectName, string filePath)
        {
            try
            {
                // Ensure the bucket exists
                bool found = await _minioClient.BucketExistsAsync(new BucketExistsArgs().WithBucket(bucketName));
                if (!found)
                {
                    await _minioClient.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucketName));
                }

                // Upload the file
                // await _minioClient.PutObjectAsync(bucketName, objectName, filePath);

                await _minioClient.PutObjectAsync(new PutObjectArgs()
                    .WithBucket(bucketName)
                    .WithObject(objectName)
                    .WithFileName(filePath));

                Console.WriteLine($"File '{filePath}' uploaded to bucket '{bucketName}' as '{objectName}'.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error uploading file to MinIO: {ex.Message}");
            }
        }
    }
}
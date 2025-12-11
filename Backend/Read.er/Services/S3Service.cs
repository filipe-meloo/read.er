using Amazon.S3;
using Amazon.S3.Transfer;
using Microsoft.Extensions.Options;
using Read.er.Models;

public class S3Service
{
    private readonly IAmazonS3 _s3Client;
    private readonly S3Settings _settings;

    public S3Service(IOptions<S3Settings> settings)
    {
        _settings = settings.Value;
        _s3Client = new AmazonS3Client(
            _settings.AccessKey,
            _settings.SecretKey,
            new AmazonS3Config
            {
                ServiceURL = "http://s3.eu-north-1.amazonaws.com",
                ForcePathStyle = true // Se necessário
            }
        );
        // Certifique-se de definir a região corretamente
        Amazon.RegionEndpoint.GetBySystemName(_settings.Region);
    }


    /// <summary>
    /// Asynchronously uploads a file to an Amazon S3 bucket.
    /// </summary>
    /// <param name="fileStream">The stream of the file to be uploaded.</param>
    /// <param name="fileName">The name to assign to the file in the S3 bucket.</param>
    /// <param name="contentType">The MIME type of the file being uploaded.</param>
    /// <returns>A task that represents the asynchronous operation. The task result contains the URL of the uploaded file.</returns>
    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType)
    {
        var uploadRequest = new TransferUtilityUploadRequest
        {
            InputStream = fileStream,
            Key = fileName,
            BucketName = _settings.BucketName,
            ContentType = contentType,
            CannedACL = S3CannedACL.PublicRead
        };

        var transferUtility = new TransferUtility(_s3Client);
        await transferUtility.UploadAsync(uploadRequest);

        // Certifique-se de retornar o URL HTTPS correto
        return $"http://{_settings.BucketName}.s3.{_settings.Region}.amazonaws.com/{fileName}";
    }

}

using System;
    namespace Read.er.Models;

    /// <summary>
    /// Represents the settings required to configure an Amazon S3 client.
    /// </summary>
    public class S3Settings
    {
        public string AccessKey { get; set; }
        public string SecretKey { get; set; }
        public string Region { get; set; }
        public string BucketName { get; set; }
    }


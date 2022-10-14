# Build the S3 Bucket
resource "aws_s3_bucket" "ph_bucket" {
  bucket = "powerhouse.com"

  tags = {
    Name = "PH-bucket"
  }
}

#Add Bucker versioning
resource "aws_s3_bucket_versioning" "ph_bucket_versioning" {
  bucket = aws_s3_bucket.ph_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Build the bucket acces control list
resource "aws_s3_bucket_acl" "ph_bucket_acl" {
  bucket = aws_s3_bucket.ph_bucket.id
  acl    = "private"
}

#Upadate bucket Policy for Cloudfront 
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ph_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.ph_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "ph_bucket_policy" {
  bucket = aws_s3_bucket.ph_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

#Website Hosting conf
resource "aws_s3_bucket_website_configuration" "ph_wh" {
  bucket = aws_s3_bucket.ph_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}
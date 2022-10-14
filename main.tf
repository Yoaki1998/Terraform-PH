terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "eu-west-3"
  shared_credentials_files = ["/home/yoaki/.aws/credentials"]
}

#Create a CF AOI
resource "aws_cloudfront_origin_access_identity" "ph_oai" {
}

# Build the S3 Bucket
resource "aws_s3_bucket" "ph_bucket" {
  bucket = "powerhouse.com"

  tags = {
    Name = "PH-bucket"
  }
}

#Website Hosting conf
resource "aws_s3_bucket_website_configuration" "ph_wh" {
  bucket = aws_s3_bucket.ph_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}

#Add Bucker versioning
resource "aws_s3_bucket_versioning" "ph_bucket_versioning" {
  bucket = aws_s3_bucket.ph_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
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

# Build the bucket acces control list
resource "aws_s3_bucket_acl" "ph_bucket_acl" {
  bucket = aws_s3_bucket.ph_bucket.id
  acl    = "private"
}

locals {
  s3_origin_id = "ph-project-serveless-app"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.ph_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.ph_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"


  # aliases = ["powerhouse.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
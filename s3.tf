resource "aws_s3_bucket" "portfolio" {
  bucket = "portfolio.${var.domain_name}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_only" {
  bucket = aws_s3_bucket.portfolio.id
  policy = data.aws_iam_policy_document.allow_cloudfront_only.json
}

data "aws_iam_policy_document" "allow_cloudfront_only" {
  statement {
    sid = "AllowCloudFrontServicePrincipal"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.portfolio.arn}/*",
    ]
    
    condition {
        test = "StringEquals"
        variable = "AWS:SourceArn"
        values = [aws_cloudfront_distribution.portfolio.arn]
    }
  }
}


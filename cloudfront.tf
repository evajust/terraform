locals {
  s3_origin_id = "S3Origin"
}

resource "aws_cloudfront_distribution" "portfolio" {
  origin {
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cf_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name]

  default_cache_behavior {
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  price_class = "PriceClass_100"

  viewer_certificate {
      acm_certificate_arn = var.ssl_cert_arn
      minimum_protocol_version = "TLSv1.2_2021"
      ssl_support_method = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "cf_oac" {
    name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    description = "OAC Config for the S3 bucket"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}


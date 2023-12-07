output "cloudfront_id" {
  description = "ID of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.portfolio.id
}

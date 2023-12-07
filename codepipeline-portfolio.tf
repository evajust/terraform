// Service Role Configuration
data "aws_iam_policy_document" "codepipeline_base_assume_role" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_portfolio" {
  name               = "CodePipelineServiceRole-Portfolio"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_base_assume_role.json
  managed_policy_arns = [aws_iam_policy.codepipeline_base.arn]
}

// Artifact Store Bucket
resource "aws_s3_bucket" "artifact_store_codepipeline" {
  bucket = "codepipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_codepipeline" {
  bucket = "codepipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_codestarconnections_connection" "portfolio_repo" {
  name          = "portfolio_repo"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "portfolio" {
  name     = "Portfolio"
  role_arn = aws_iam_role.codepipeline_portfolio.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store_codepipeline.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "source_variables"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.portfolio_repo.arn
        FullRepositoryId = "evajust/portfolio"
        BranchName       = "main"
      }
    }
  }
  stage {
    name = "Deploy"

    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName     = resource.aws_s3_bucket.portfolio.id
        Extract        = true
      }
    }
  }
  stage {
    name = "Invoke"

    action {
      name            = "ClearCFCache"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
          FunctionName = "clear_cloudfront_cache"
          UserParameters = "evansjt.com"
      }
    }
  }
}

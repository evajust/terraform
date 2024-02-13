// Service Role Configuration
resource "aws_iam_role" "codepipeline_lambda" {
  name               = "CodePipelineServiceRole-Lambda"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_base_assume_role.json
  managed_policy_arns = [aws_iam_policy.codepipeline_base.arn]
}

resource "aws_codestarconnections_connection" "lambda_repo" {
  name          = "lambda_repo"
  provider_type = "GitHub"
}

//IAM Policies
data "aws_iam_policy_document" "project_lambda" {
  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:logs:us-east-1:947126890226:log-group:/aws/codebuild/Visitor-Counter-Project",
      "arn:aws:logs:us-east-1:947126890226:log-group:/aws/codebuild/Visitor-Counter-Project:*",
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::codepipeline-us-east-1-*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:codebuild:us-east-1:947126890226:report-group/Visitor-Counter-Project-*"]

    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
    ]
  }
}

data "aws_iam_policy_document" "lambda_update" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["lambda:UpdateFunctionCode"]
  }
}

resource "aws_iam_role" "codebuild-project-lambda" {
  name               = "codebuild-Lambda-Project-service-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codebuild_base_assume_role.json
  inline_policy {
      name = "codebuildbase-Project-Lambda"
      policy = data.aws_iam_policy_document.project_lambda.json
  }
  inline_policy {
      name = "Lambda-Update"
      policy = data.aws_iam_policy_document.lambda_update.json
  }
}

// CodeBuild Project
resource "aws_codebuild_project" "lambda_update" {
    name = "Lambda-Update"
    description = "Project to Update Lambda Functions"
    service_role = aws_iam_role.codebuild-project-lambda.arn

    artifacts {
        type = "CODEPIPELINE"
    }

    source {
        type = "CODEPIPELINE"
        git_clone_depth = 0
    }

    environment {
        image = "aws/codebuild/amazonlinux-x86_64-lambda-standard:python3.11"
        type = "LINUX_LAMBDA_CONTAINER"
        compute_type = "BUILD_LAMBDA_1GB"
    }

    logs_config {
        cloudwatch_logs {
            status = "ENABLED"
        }
    }
}
resource "aws_codepipeline" "lambda" {
  name     = "Lambda_Functions"
  role_arn = aws_iam_role.codepipeline_lambda.arn

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
      namespace        = "lambda_source_variables"
      output_artifacts = ["lambda_source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.lambda_repo.arn
        FullRepositoryId = "evajust/lambda-functions"
        BranchName       = "main"
      }
    }
  }
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["lambda_source_output"]
      output_artifacts = ["lambda_build_output"]
      version          = "1"
      namespace        = "BuildVariables"

      configuration = {
        ProjectName = "Lambda-Update"
      }
    }
  }
}

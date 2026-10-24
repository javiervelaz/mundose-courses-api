output "aws_role_arn" {
  description = "Cargar como variable de repo AWS_ROLE_ARN"
  value       = aws_iam_role.deploy.arn
}

output "tf_state_bucket" {
  description = "Cargar como variable de repo TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.bucket
}

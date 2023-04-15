resource "aws_iam_role" "sstack" {
  name               = "sstack_role"
  assume_role_policy = file("${path.module}/policies/role.json")
}

resource "aws_iam_role_policy" "sstack" {
  name   = "sstack_policy"
  policy = file("${path.module}/policies/policy.json")
  role   = aws_iam_role.sstack.id
}

resource "aws_iam_instance_profile" "sstack" {
  name = "sstack_profile"
  path = "/"
  role = aws_iam_role.sstack.name
}

resource "aws_iam_user" "sstack_s3" {
  name = "sstack_s3_user"
}

resource "aws_iam_access_key" "sstack_s3" {
  user = aws_iam_user.sstack_s3.name
}

resource "aws_iam_user_policy" "sstack_s3_ro" {
  name   = "s3_policy"
  policy = file("${path.module}/policies/policy_s3.json")
  user   = aws_iam_user.sstack_s3.name
}
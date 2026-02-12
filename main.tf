resource "aws_iam_openid_connect_provider" "this" {
  url             = var.provider_url
  client_id_list  = var.client_id_list
  thumbprint_list = var.thumbprint_list
  tags            = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  for_each = var.roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    dynamic "condition" {
      for_each = each.value.oidc_conditions
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "this" {
  for_each           = var.roles
  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
  tags               = merge(var.tags, { Name = each.value.role_name })
}

resource "aws_iam_role_policy" "this" {
  for_each = var.roles
  name     = "${each.value.role_name}-permissions"
  role     = aws_iam_role.this[each.key].id
  policy   = each.value.policy_json
}

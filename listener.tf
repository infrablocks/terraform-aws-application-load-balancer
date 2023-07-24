resource "aws_lb_listener" "listener" {
  for_each = {
    for listener in var.listeners : listener.key => listener
  }

  load_balancer_arn = aws_lb.load_balancer.arn

  port = each.value.port
  protocol = each.value.protocol

  ssl_policy = each.value.ssl_policy
  certificate_arn = each.value.certificate_arn

  dynamic "default_action" {
    for_each = each.value.default_actions

    content {
      type = default_action.value.type
      target_group_arn = default_action.value.target_group_key == null ? null : aws_lb_target_group.target_group[default_action.value.target_group_key].arn

      dynamic "authenticate_oidc" {
        for_each = default_action.value.type == "authenticate-oidc" ? [default_action.value] : []

        content {
          authorization_endpoint = authenticate_oidc.value.authorization_endpoint
          client_id = authenticate_oidc.value.client_id
          client_secret = authenticate_oidc.value.client_secret
          issuer = authenticate_oidc.value.issuer
          token_endpoint = authenticate_oidc.value.token_endpoint
          user_info_endpoint = authenticate_oidc.value.user_info_endpoint
        }
      }
    }
  }
}

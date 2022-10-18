data "terraform_remote_state" "prerequisites" {
  backend = "local"

  config = {
    path = "${path.module}/../../../../state/prerequisites.tfstate"
  }
}

module "application_load_balancer" {
  source = "../../../.."

  region = var.region
  vpc_id = data.terraform_remote_state.prerequisites.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.prerequisites.outputs.subnet_ids

  component = var.component
  deployment_identifier = var.deployment_identifier

  idle_timeout = var.idle_timeout

  expose_to_public_internet = var.expose_to_public_internet

  security_groups = var.security_groups

  dns = var.dns

  target_groups = var.target_groups
  listeners = var.listeners
}

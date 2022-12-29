Terraform AWS Application Load Balancer
===================================

[![Version](https://img.shields.io/github/v/tag/infrablocks/terraform-aws-application-load-balancer?label=version&sort=semver)](https://github.com/infrablocks/terraform-aws-application-load-balancer/tags)
[![Build Pipeline](https://img.shields.io/circleci/build/github/infrablocks/terraform-aws-application-load-balancer/main?label=build-pipeline)](https://app.circleci.com/pipelines/github/infrablocks/terraform-aws-application-load-balancer?filter=all)
[![Maintainer](https://img.shields.io/badge/maintainer-go--atomic.io-red)](https://go-atomic.io)

A Terraform module for building an application load balancer in AWS.

The load balancer requires:

* An existing VPC
* Some existing subnets
* A domain name and public and private hosted zones

The application load balancer consists of:

* An ALB
    * Deployed across the provided subnet IDs
    * Either internal or internet-facing as specified
    * With a health check using the specified target
    * With connection draining as specified
* A security group allowing access to/from the load balancer according to the
  specified access control and egress CIDRs configuration
* A security group for use by instances allowing access from the load balancer
  according to the specified access control configuration
* A DNS entry
    * In the public hosted zone if specified
    * In the private hosted zone if specified

Usage
-----

To use the module, include something like the following in your Terraform
configuration:

```terraform
module "application_load_balancer" {
  source  = "infrablocks/application-load-balancer/aws"
  version = "4.0.0"

  region     = "eu-west-2"
  vpc_id     = "vpc-fb7dc365"
  subnet_ids = "subnet-ae4533c4,subnet-443e6b12"

  component             = "important-component"
  deployment_identifier = "production"

  domain_name     = "example.com"
  public_zone_id  = "Z1WA3EVJBXSQ2V"
  private_zone_id = "Z3CVA9QD5NHSW3"

  listeners = [
    {
      lb_port            = 443
      lb_protocol        = "HTTPS"
      instance_port      = 443
      instance_protocol  = "HTTPS"
      ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/default"
    },
    {
      lb_port           = 6567
      lb_protocol       = "TCP"
      instance_port     = 6567
      instance_protocol = "TCP"
    }
  ]

  access_control = [
    {
      lb_port       = 443
      instance_port = 443
      allow_cidr    = '0.0.0.0/0'
    },
    {
      lb_port       = 6567
      instance_port = 6567
      allow_cidr    = '10.0.0.0/8'
    }
  ]

  egress_cidrs = '10.0.0.0/8'

  health_check_target              = 'HTTPS:443/ping'
  health_check_timeout             = 10
  health_check_interval            = 30
  health_check_unhealthy_threshold = 5
  health_check_healthy_threshold   = 5

  enable_cross_zone_load_balancing = 'yes'

  enable_connection_draining  = 'yes'
  connection_draining_timeout = 60

  idle_timeout = 60

  expose_to_public_internet = 'yes'
}
```

As mentioned above, the load balancer deploys into an existing base network.
Whilst the base network can be created using any mechanism you like, the
[AWS Base Networking](https://github.com/infrablocks/terraform-aws-base-networking)
module will create everything you need. See the
[docs](https://github.com/infrablocks/terraform-aws-base-networking/blob/main/README.md)
for usage instructions.

See the
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/application-load-balancer/aws/latest)
for more details.

### Inputs

| Name                               | Description                                                                                                                                                                                                                                       |                                                                            Default                                                                             | Required |
|------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------:|:--------:|
| `region`                           | The region into which to deploy the load balancer.                                                                                                                                                                                                |                                                                               -                                                                                |   Yes    |
| `vpc_id`                           | The ID of the VPC into which to deploy the load balancer.                                                                                                                                                                                         |                                                                               -                                                                                |   Yes    |
| `subnet_ids`                       | The IDs of the subnets for the ALB.                                                                                                                                                                                                               |                                                                               -                                                                                |   Yes    |
| `component`                        | The component for which the load balancer is being created.                                                                                                                                                                                       |                                                                               -                                                                                |   Yes    |
| `deployment_identifier`            | An identifier for this instantiation.                                                                                                                                                                                                             |                                                                               -                                                                                |   Yes    |
| `idle_timeout`                     | The time after which idle connections are closed.                                                                                                                                                                                                 |                                                                              `60`                                                                              |    No    |
| `expose_to_public_internet`        | Whether or not to the ALB should be internet facing (`"yes"` or `"no"`).                                                                                                                                                                          |                                                                             `"no"`                                                                             |    No    |
| `security_groups`                  | Details of security groups to add to the ALB, including the default security group.                                                                                                                                                               | `{ default: { associate: "yes", ingress_rule: { include: "yes", cidrs: null }, egress_rule: { include: "yes", from_port: 0, to_port: 65535, cidrs: null } } }` |    No    |
| `dns`                              | Details of DNS records to point at the created load balancer. Expects a domain_name, used to create each record and a list of records to create. Each record object includes a zone_id referencing the hosted zone in which to create the record. |                                                              `{ domain_name: null, records: [] }`                                                              |    No    |
| `target_groups`                    | Details of target groups to create.                                                                                                                                                                                                               |                                                                              `[]`                                                                              |    No    |
| `listeners`                        | Details of listeners to create.                                                                                                                                                                                                                   |                                                                              `[]`                                                                              |    No    |

### Outputs

| Name            | Description                                           |
|-----------------|-------------------------------------------------------|
| `name`          | The name of the created ALB.                          |
| `vpc_id`        | The VPC ID of the created ALB.                        |
| `id`            | The ID of the created ALB.                            |
| `arn`           | The ARN of the created ALB.                           |
| `arn_suffix`    | The ARN suffix of the created ALB.                    |
| `zone_id`       | The zone ID of the created ALB.                       |
| `dns_name`      | The DNS name of the created ALB.                      |
| `address`       | The address of the DNS record(s) for the created ALB. |
| `target_groups` | Details of the created target groups.                 |
| `listeners`     | Details pf the created listeners.                     |

### Compatibility

This module is compatible with Terraform versions greater than or equal to
Terraform 1.0 and Terraform AWS provider versions greater than or equal to 3.27.

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed
on your development machine:

* Ruby (3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv
* aws-vault

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```shell
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 3.1.1
rbenv rehash
rbenv local 3.1.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# aws-vault
brew cask install

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

Running the build requires an AWS account and AWS credentials. You are free to
configure credentials however you like as long as an access key ID and secret
access key are available. These instructions utilise
[aws-vault](https://github.com/99designs/aws-vault) which makes credential
management easy and secure.

To run the full build, including unit and integration tests, execute:

```shell
aws-vault exec <profile> -- ./go
```

To run the unit tests, execute:

```shell
aws-vault exec <profile> -- ./go test:unit
```

To run the integration tests, execute:

```shell
aws-vault exec <profile> -- ./go test:integration
```

To provision the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:provision[<deployment_identifier>]
```

To destroy the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:destroy[<deployment_identifier>]
```

Configuration parameters can be overridden via environment variables. For
example, to run the unit tests with a seed of `"testing"`, execute:

```shell
SEED=testing aws-vault exec <profile> -- ./go test:unit
```

When a seed is provided via an environment variable, infrastructure will not be
destroyed at the end of test execution. This can be useful during development
to avoid lengthy provision and destroy cycles.

To subsequently destroy unit test infrastructure for a given seed:

```shell
FORCE_DESTROY=yes SEED=testing aws-vault exec <profile> -- ./go test:unit
```

### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```shell
ssh-keygen -m PEM -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Generating a self-signed certificate

To generate a self signed certificate:

```shell
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

To decrypt the resulting key:

```shell
openssl rsa -in key.pem -out ssl.key
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```shell
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```shell
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/terraform-aws-application-load-balancer.
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

The library is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

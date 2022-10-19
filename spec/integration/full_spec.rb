# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'full' do
  let(:component) do
    var(role: :full, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:domain_name) do
    var(role: :full, name: 'domain_name')
  end
  let(:public_zone_id) do
    var(role: :full, name: 'public_zone_id')
  end
  let(:private_zone_id) do
    var(role: :full, name: 'private_zone_id')
  end
  let(:name) do
    output(role: :full, name: 'name')
  end
  let(:arn) do
    output(role: :full, name: 'arn')
  end
  let(:subnet_ids) do
    output(role: :full, name: 'subnet_ids')
  end
  let(:vpc_cidr) do
    output(role: :full, name: 'vpc_cidr')
  end
  let(:vpc_id) do
    output(role: :full, name: 'vpc_id')
  end

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(role: :full)
  end

  describe 'ALB' do
    subject(:load_balancer) { alb(name) }

    it { is_expected.to exist }
    its(:scheme) { is_expected.to eq('internet-facing') }

    it 'has the correct subnets' do
      subnet_ids.each do |subnet|
        expect(load_balancer).to(have_subnet(subnet))
      end
    end

    it 'outputs the zone ID' do
      expect(output(role: :full, name: 'zone_id'))
        .to(eq(load_balancer.canonical_hosted_zone_id))
    end

    it 'outputs the DNS name' do
      expect(output(role: :full, name: 'dns_name'))
        .to(eq(load_balancer.dns_name))
    end

    describe 'tags' do
      subject(:tags) do
        elbv2_client
          .describe_tags(resource_arns: [arn])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
      end

      it {
        expect(tags)
          .to(include({
                        key: 'Name',
                        value: "#{component}-#{deployment_identifier}"
                      }))
      }

      it {
        expect(tags)
          .to(include({
                        key: 'Component',
                        value: component
                      }))
      }

      it {
        expect(tags)
          .to(include({
                        key: 'DeploymentIdentifier',
                        value: deployment_identifier
                      }))
      }
    end
  end

  describe 'DNS records' do
    let(:public_hosted_zone) do
      route53_hosted_zone(public_zone_id)
    end
    let(:private_hosted_zone) do
      route53_hosted_zone(private_zone_id)
    end
    let(:load_balancer) do
      alb(name)
    end

    it 'outputs the address' do
      expect(output(role: :full, name: 'address'))
        .to(eq("#{component}-#{deployment_identifier}.#{domain_name}"))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'creates a DNS entry in each provided zone' do
      expect(public_hosted_zone)
        .to(have_record_set(
          "#{component}-#{deployment_identifier}.#{domain_name}."
        )
              .alias(
                "#{load_balancer.dns_name}.",
                load_balancer.canonical_hosted_zone_id
              ))
      expect(private_hosted_zone)
        .to(have_record_set(
          "#{component}-#{deployment_identifier}.#{domain_name}."
        )
              .alias(
                "#{load_balancer.dns_name}.",
                load_balancer.canonical_hosted_zone_id
              ))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'listener' do
    subject(:listener) { alb_listener(listeners[:default][:arn]) }

    let(:listeners) { output(role: :full, name: 'listeners') }
    let(:certificate_arn) { output(role: :full, name: 'certificate_arn') }

    it { is_expected.to(exist) }

    its(:port) do
      is_expected.to(eq(443))
    end

    its(:protocol) { is_expected.to(eq('HTTPS')) }

    its(:ssl_policy) do
      is_expected.to(eq('ELBSecurityPolicy-TLS-1-2-Ext-2018-06'))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses the provided certificate' do
      certificates = listener.certificates

      expect(certificates.length).to(eq(1))
      expect(certificates.first.certificate_arn).to(eq(certificate_arn))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'security group' do
    subject(:load_balancer) { alb(name) }

    let(:security_groups) do
      load_balancer.security_groups.map { |sg| security_group(sg) }
    end

    # rubocop:disable RSpec/MultipleExpectations
    it('associates a security group allowing inbound TCP ' \
       'for all listener ports for the supplied ingress CIDRs') do
      expect(security_groups.length).to(eq(1))

      security_group = security_groups.first

      expect(security_group.inbound_rule_count).to(eq(1))

      ingress_rule = security_group.ip_permissions.first

      expect(ingress_rule.from_port).to(eq(443))
      expect(ingress_rule.to_port).to(eq(443))
      expect(ingress_rule.ip_protocol).to(eq('tcp'))
      expect(ingress_rule.ip_ranges.map(&:cidr_ip))
        .to(eq([vpc_cidr]))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it('associates a security group allowing outbound TCP ' \
       'for all ports for the supplied egress CIDRs') do
      expect(security_groups.length).to(eq(1))

      security_group = security_groups.first

      expect(security_group.outbound_rule_count).to(eq(1))

      egress_rule = security_group.ip_permissions_egress.first

      expect(egress_rule.from_port).to(eq(0))
      expect(egress_rule.to_port).to(eq(65_535))
      expect(egress_rule.ip_protocol).to(eq('tcp'))
      expect(egress_rule.ip_ranges.map(&:cidr_ip))
        .to(eq([vpc_cidr]))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'target group' do
    subject(:target_group) { alb_target_group(target_group_name) }

    let(:target_groups) do
      output(role: :full, name: 'target_groups')
    end

    let(:target_group_name) { target_groups[:default][:name] }
    let(:target_group_arn) { target_groups[:default][:arn] }

    let(:alb_name) { output(role: :full, name: 'name') }

    it { is_expected.to(exist) }

    it { is_expected.to(belong_to_alb(alb_name)) }
    it { is_expected.to(belong_to_vpc(vpc_id)) }

    its(:protocol) { is_expected.to(eq('HTTP')) }
    its(:port) { is_expected.to(eq(80)) }
    its(:target_type) { is_expected.to(eq('instance')) }

    describe 'healthcheck' do
      its(:health_check_protocol) do
        is_expected.to(eq('HTTP'))
      end

      its(:health_check_port) do
        is_expected.to(eq('80'))
      end

      its(:health_check_path) do
        is_expected.to(eq('/health'))
      end

      its(:health_check_interval_seconds) do
        is_expected.to(eq(30))
      end
    end

    describe 'tags' do
      subject(:tags) do
        elbv2_client
          .describe_tags(resource_arns: [target_group_arn])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
      end

      let(:port) { 80 }
      let(:protocol) { 'HTTP' }

      it do
        name = "#{component}-#{deployment_identifier}-#{port}-#{protocol}"
        expect(tags).to(include({ key: 'Name', value: name }))
      end

      it { is_expected.to(include({ key: 'Component', value: component })) }

      it {
        expect(tags)
          .to(include({ key: 'DeploymentIdentifier',
                        value: deployment_identifier }))
      }
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

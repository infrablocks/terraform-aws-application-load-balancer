require 'spec_helper'
require 'awspec/type/route53_hosted_zone'

describe 'DNS Records' do
  include_context :terraform

  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }

  let(:name) { output_for(:harness, 'name') }

  def domain_name
    configuration.for(:harness).domain_name
  end
  def public_zone_id
    configuration.for(:harness).public_zone_id
  end
  def private_zone_id
    configuration.for(:harness).private_zone_id
  end

  let(:load_balancer) { alb(name) }

  let(:public_hosted_zone) {
    route53_hosted_zone(public_zone_id)
  }

  let(:private_hosted_zone) {
    route53_hosted_zone(private_zone_id)
  }

  it 'outputs the address' do
    expect(output_for(:harness, 'address'))
        .to(eq("#{component}-#{deployment_identifier}.#{domain_name}"))
  end

  context 'when passed multiple zones in which to create records' do
    before(:all) do
      reprovision(
          dns: {
              domain_name: domain_name,
              records: [
                  {zone_id: public_zone_id},
                  {zone_id: private_zone_id},
              ]
          })
    end

    it 'creates a DNS entry in each provided zone' do
      expect(public_hosted_zone)
          .to(have_record_set(
              "#{component}-#{deployment_identifier}.#{domain_name}.")
              .alias(
                  "#{load_balancer.dns_name}.",
                  load_balancer.canonical_hosted_zone_id))
      expect(private_hosted_zone)
          .to(have_record_set(
              "#{component}-#{deployment_identifier}.#{domain_name}.")
              .alias(
                  "#{load_balancer.dns_name}.",
                  load_balancer.canonical_hosted_zone_id))
    end
  end

  context 'when passed no zones in which to create records' do
    before(:all) do
      reprovision(
          dns: {
              domain_name: domain_name,
              records: []
          })
    end

    it 'does not create any DNS entries' do
      expect(public_hosted_zone)
          .not_to(have_record_set(
              "#{component}-#{deployment_identifier}.#{domain_name}.")
              .alias(
                  "#{load_balancer.dns_name}.",
                  load_balancer.canonical_hosted_zone_id))
      expect(private_hosted_zone)
          .not_to(have_record_set(
              "#{component}-#{deployment_identifier}.#{domain_name}.")
              .alias(
                  "#{load_balancer.dns_name}.",
                  load_balancer.canonical_hosted_zone_id))
    end
  end
end

require 'spec_helper'

describe 'Security Groups' do
  let(:component) {vars.component}
  let(:deployment_identifier) {vars.deployment_identifier}

  let(:name) {output_for(:harness, 'name')}

  subject {alb(name)}

  let(:security_groups) {
    subject.security_groups.map { |sg| security_group(sg) }
  }

  context "when including default security group" do
    before(:all) do
      reprovision(associate_default_security_group: "yes")
    end

    it('associates a security group allowing inbound TCP ' +
        'for all listener ports for the supplied ingress CIDRs') do
      ingress_cidr = configuration
          .for(:harness)
          .default_security_group_ingress_cidr
      listener_port = vars.listeners[0]["port"].to_i

      expect(security_groups.length).to(eq(1))

      security_group = security_groups.first

      expect(security_group.inbound_rule_count).to(eq(1))

      ingress_rule = security_group.ip_permissions.first

      expect(ingress_rule.from_port).to(eq(listener_port))
      expect(ingress_rule.to_port).to(eq(listener_port))
      expect(ingress_rule.ip_protocol).to(eq('tcp'))
      expect(ingress_rule.ip_ranges.map(&:cidr_ip))
          .to(eq([ingress_cidr]))
    end

    it('associates a security group allowing outbound TCP ' +
        'for all ports for the supplied egress CIDRs') do
      egress_cidr = configuration
          .for(:harness)
          .default_security_group_egress_cidr

      expect(security_groups.length).to(eq(1))

      security_group = security_groups.first

      expect(security_group.outbound_rule_count).to(eq(1))

      egress_rule = security_group.ip_permissions_egress.first

      expect(egress_rule.from_port).to(eq(0))
      expect(egress_rule.to_port).to(eq(0))
      expect(egress_rule.ip_protocol).to(eq('tcp'))
      expect(egress_rule.ip_ranges.map(&:cidr_ip))
          .to(eq([egress_cidr]))
    end
  end
end
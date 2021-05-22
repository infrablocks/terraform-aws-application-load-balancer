require 'spec_helper'

describe 'Target Group' do
  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }

  let(:target_groups) do
    output_for(:harness, 'target_groups')
  end

  let(:name) { target_groups["default"]["name"] }
  let(:arn) { target_groups["default"]["arn"] }

  let(:vpc) { output_for(:harness, 'vpc_id') }

  let(:alb) { output_for(:harness, 'name') }

  subject { alb_target_group(name) }

  it { should exist }

  it { should belong_to_alb(alb) }
  it { should belong_to_vpc(vpc) }

  its(:protocol) { should eq vars.target_groups[0]["protocol"] }
  its(:port) { should eq vars.target_groups[0]["port"].to_i }
  its(:target_type) { should eq vars.target_groups[0]["target_type"] }

  fcontext 'healthcheck' do
    its(:health_check_protocol) do
      should eq vars.target_groups[0]["health_check"]["protocol"]
    end
    its(:health_check_port) do
      should eq vars.target_groups[0]["health_check"]["port"]
    end
    its(:health_check_path) do
      should eq vars.target_groups[0]["health_check"]["path"]
    end
    its(:health_check_interval_seconds) do
      should eq vars.target_groups[0]["health_check"]["interval"].to_i
    end
  end

  context 'tags' do
    subject do
      elbv2_client
          .describe_tags(resource_arns: [arn])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
    end

    let(:target_group) { vars.target_groups[0] }
    let(:port) { target_group["port"] }
    let(:protocol) { target_group["protocol"] }

    it do

      should include({
          key: 'Name',
          value: "#{component}-#{deployment_identifier}-#{port}-#{protocol}"
      })
    end
    it { should include({key: 'Component', value: component}) }
    it { should include({key: 'DeploymentIdentifier',
        value: deployment_identifier}) }
  end
end

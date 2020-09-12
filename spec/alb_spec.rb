require 'spec_helper'

describe 'ALB' do
  let(:component) {vars.component}
  let(:deployment_identifier) {vars.deployment_identifier}

  let(:name) {output_for(:harness, 'name')}
  let(:arn) {output_for(:harness, 'arn')}

  let(:subnet_ids) do
    output_for(:prerequisites, 'subnet_ids', parse: true)
  end

  subject {alb(name)}

  it {should exist}
  its(:scheme) {should eq('internal')}

  it 'has the correct subnets' do
    subnet_ids.each do |subnet|
      expect(subject).to(have_subnet(subnet))
    end
  end

  it 'outputs the zone ID' do
    expect(output_for(:harness, 'zone_id'))
        .to(eq(subject.canonical_hosted_zone_id))
  end

  it 'outputs the DNS name' do
    expect(output_for(:harness, 'dns_name'))
        .to(eq(subject.dns_name))
  end

  context 'tags' do
    subject do
      elbv2_client
          .describe_tags(resource_arns: [arn])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
    end

    it {should include({key: 'Name',
                        value: "alb-#{component}-#{deployment_identifier}"})}
    it {should include({key: 'Component', value: component})}
    it {should include({key: 'DeploymentIdentifier',
                        value: deployment_identifier})}
  end

  context 'attributes' do
    subject do
      elbv2_client
          .describe_load_balancer_attributes(load_balancer_arn: arn)
          .map(&:to_h)[0][:attributes]
          .map{|x | Hash[x[:key], x[:value]]}
          .reduce({}, :merge)
    end

    it 'uses the provided flag for whether s3 access logs are enabled' do
      expect(subject['access_logs.s3.enabled']).to eq('false')
    end

    it 'uses the provided value for the s3 access logs prefix' do
      expect(subject['access_logs.s3.prefix']).to eq('')
    end

    it 'uses the provided flag for whether deletion protection is enabled' do
      expect(subject['deletion_protection.enabled']).to eq('false')
    end
  end

  context 'when ELB is exposed to the public internet' do
    before(:all) do
      reprovision(expose_to_public_internet: 'yes')
    end

    its(:scheme) { should eq('internet-facing') }
  end

  context 'when ELB is not exposed to the public internet' do
    before(:all) do
      reprovision(expose_to_public_internet: 'no')
    end

    its(:scheme) { should eq('internal') }
  end
end

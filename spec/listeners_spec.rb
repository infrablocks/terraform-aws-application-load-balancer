require 'spec_helper'

describe 'Listener' do
  let(:component) {vars.component}
  let(:deployment_identifier) {vars.deployment_identifier}

  let(:listeners) {output_for(:harness, 'listeners')}
  let(:certificate_arn) {output_for(:prerequisites, 'certificate_arn')}

  subject {alb_listener(listeners[:default][:arn])}

  it {should exist}
  its(:port) {
    should eq vars.listeners[0]["port"].to_i
  }
  its(:protocol) {should eq vars.listeners[0]["protocol"]}

  it 'uses the provided certificate' do
    certificates = subject.certificates

    expect(certificates.length).to(eq(1))
    expect(certificates.first.certificate_arn).to(eq(certificate_arn))
  end
end

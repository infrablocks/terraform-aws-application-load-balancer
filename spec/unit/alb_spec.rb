# frozen_string_literal: true

require 'spec_helper'

describe 'ALB' do
  describe 'by default' do
    let(:subnet_ids) do
      output(role: :prerequisites, name: 'subnet_ids')
    end
    let(:component) do
      var(role: :root, name: 'component')
    end
    let(:deployment_identifier) do
      var(role: :root, name: 'deployment_identifier')
    end

    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a load balancer' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .once)
    end

    it 'uses a load balancer type of application' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:load_balancer_type, 'application'))
    end

    it 'uses the provided subnets' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:subnets, subnet_ids))
    end

    it 'marks the load balancer as internal' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:internal, true))
    end

    it 'uses an idle timeout of 60s' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:idle_timeout, 60))
    end

    it 'adds tags to the load balancer' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(
                :tags, {
                  Name: "#{component}-#{deployment_identifier}",
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                }
              ))
    end

    it 'outputs the load balancer name' do
      expect(@plan)
        .to(include_output_creation(name: 'name'))
    end

    it 'outputs the load balancer ARN' do
      expect(@plan)
        .to(include_output_creation(name: 'arn'))
    end

    it 'outputs the load balancer ARN suffix' do
      expect(@plan)
        .to(include_output_creation(name: 'arn_suffix'))
    end

    it 'outputs the load balancer ID' do
      expect(@plan)
        .to(include_output_creation(name: 'id'))
    end

    it 'outputs the load balancer VPC ID' do
      expect(@plan)
        .to(include_output_creation(name: 'vpc_id'))
    end

    it 'outputs the load balancer zone ID' do
      expect(@plan)
        .to(include_output_creation(name: 'zone_id'))
    end

    it 'outputs the load balancer DNS name' do
      expect(@plan)
        .to(include_output_creation(name: 'dns_name'))
    end
  end

  describe 'when expose_to_public_internet is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.expose_to_public_internet = 'yes'
      end
    end

    it 'marks the load balancer as internet-facing' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:internal, false))
    end
  end

  describe 'when expose_to_public_internet is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.expose_to_public_internet = 'no'
      end
    end

    it 'marks the load balancer as internal' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:internal, true))
    end
  end
end

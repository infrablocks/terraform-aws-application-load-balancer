# frozen_string_literal: true

require 'spec_helper'

describe 'target group' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:vpc_id) do
    output(role: :prerequisites, name: 'vpc_id')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'does not create any target groups' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_lb_target_group'))
    end

    it 'outputs an empty map of target groups' do
      expect(@plan)
        .to(include_output_creation(name: 'target_groups')
              .with_value({}))
    end
  end

  describe 'when one target group specified' do
    before(:context) do
      @target_group = target_group
      @plan = plan(role: :root) do |vars|
        vars.target_groups = [@target_group]
      end
    end

    it 'creates a target group' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .once)
    end

    it 'uses the provided VPC ID' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:vpc_id, vpc_id))
    end

    it 'uses the provided port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:port, @target_group[:port]))
    end

    it 'uses the provided protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:protocol, @target_group[:protocol]))
    end

    it 'uses the provided target type' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:target_type, @target_group[:target_type]))
    end

    it 'uses the provided deregistration delay' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                :deregistration_delay, @target_group[:deregistration_delay].to_s
              ))
    end

    it 'uses the provided health check path' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :path], @target_group[:health_check][:path]
              ))
    end

    it 'uses the provided health check port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :port], @target_group[:health_check][:port]
              ))
    end

    it 'uses the provided health check protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :protocol],
                @target_group[:health_check][:protocol]
              ))
    end

    it 'uses the provided health check interval' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :interval],
                @target_group[:health_check][:interval]
              ))
    end

    it 'uses the provided health check healthy threshold' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :healthy_threshold],
                @target_group[:health_check][:healthy_threshold]
              ))
    end

    it 'uses the provided health check unhealthy threshold' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :unhealthy_threshold],
                @target_group[:health_check][:unhealthy_threshold]
              ))
    end

    it 'adds tags to the target group' do
      port = @target_group[:port]
      protocol = @target_group[:protocol]

      name = "#{component}-#{deployment_identifier}-#{port}-#{protocol}"

      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                :tags, {
                  Name: name,
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                }
              ))
    end

    it 'outputs the target groups' do
      expect(@plan)
        .to(include_output_creation(name: 'target_groups'))
    end
  end

  describe 'when many target groups specified' do
    before(:context) do
      @target_group1 = target_group(
        key: 'first',
        port: 80,
        protocol: 'HTTP',
        target_type: 'instance',
        deregistration_delay: 300,
        health_check: health_check(
          path: '/health',
          port: 'traffic-port',
          protocol: 'HTTP',
          interval: 30,
          healthy_threshold: 5,
          unhealthy_threshold: 5
        )
      )
      @target_group2 = target_group(
        key: 'second',
        port: 90,
        protocol: 'HTTPS',
        target_type: 'ip',
        deregistration_delay: 90,
        health_check: health_check(
          path: '/status',
          port: '8443',
          protocol: 'HTTPS',
          interval: 45,
          healthy_threshold: 3,
          unhealthy_threshold: 3
        )
      )

      @target_groups = [@target_group1, @target_group2]

      @plan = plan(role: :root) do |vars|
        vars.target_groups = @target_groups
      end
    end

    it 'creates each target group' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .exactly(@target_groups.count).times)
    end

    it 'uses the provided ports' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port]))
      end
    end

    it 'uses the provided VPC ID' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(:vpc_id, vpc_id))
      end
    end

    it 'uses the provided protocols' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(:protocol, target_group[:protocol]))
      end
    end

    it 'uses the provided target type' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  :target_type, target_group[:target_type]
                ))
      end
    end

    it 'uses the provided deregistration delay' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  :deregistration_delay,
                  target_group[:deregistration_delay].to_s
                ))
      end
    end

    it 'uses the provided health check path' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :path],
                  target_group[:health_check][:path]
                ))
      end
    end

    it 'uses the provided health check port' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :port],
                  target_group[:health_check][:port]
                ))
      end
    end

    it 'uses the provided health check protocol' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :protocol],
                  target_group[:health_check][:protocol]
                ))
      end
    end

    it 'uses the provided health check interval' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :interval],
                  target_group[:health_check][:interval]
                ))
      end
    end

    it 'uses the provided health check healthy threshold' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :healthy_threshold],
                  target_group[:health_check][:healthy_threshold]
                ))
      end
    end

    it 'uses the provided health check unhealthy threshold' do
      @target_groups.each do |target_group|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, target_group[:port])
                .with_attribute_value(
                  [:health_check, 0, :unhealthy_threshold],
                  target_group[:health_check][:unhealthy_threshold]
                ))
      end
    end

    it 'adds tags to the target group' do
      @target_groups.each do |target_group|
        port = target_group[:port]
        protocol = target_group[:protocol]

        name = "#{component}-#{deployment_identifier}-#{port}-#{protocol}"

        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_target_group')
                .with_attribute_value(:port, port)
                .with_attribute_value(
                  :tags, {
                    Name: name,
                    Component: component,
                    DeploymentIdentifier: deployment_identifier
                  }
                ))
      end
    end

    it 'outputs the target groups' do
      expect(@plan)
        .to(include_output_creation(name: 'target_groups'))
    end
  end

  describe 'when nil values are provided for a target group' do
    before(:context) do
      @target_group = {
        key: 'default',
        port: 80,
        protocol: nil,
        target_type: nil,
        deregistration_delay: nil,
        health_check: {
          path: nil,
          port: nil,
          protocol: nil,
          interval: nil,
          healthy_threshold: nil,
          unhealthy_threshold: nil
        }
      }
      @plan = plan(role: :root) do |vars|
        vars.target_groups = [@target_group]
      end
    end

    it 'creates a target group' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .once)
    end

    it 'uses the provided port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:port, @target_group[:port]))
    end

    it 'uses HTTP for the protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:protocol, 'HTTP'))
    end

    it 'uses instance for target type' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:target_type, 'instance'))
    end

    it 'uses the default deregistration delay' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(:deregistration_delay, '300'))
    end

    it 'uses / for health check path' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value([:health_check, 0, :path], '/'))
    end

    it 'uses traffic-port for health check port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value([:health_check, 0, :port], 'traffic-port'))
    end

    it 'uses HTTP for health check protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value([:health_check, 0, :protocol], 'HTTP'))
    end

    it 'uses 30s for the health check interval' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value([:health_check, 0, :interval], 30))
    end

    it 'uses 3 for the health check healthy threshold' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value([:health_check, 0, :healthy_threshold], 3))
    end

    it 'uses 3 for the health check unhealthy threshold' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_target_group')
              .with_attribute_value(
                [:health_check, 0, :unhealthy_threshold], 3
              ))
    end
  end

  def target_group(overrides = {})
    {
      key: 'default',
      port: 80,
      protocol: 'HTTP',
      target_type: 'instance',
      deregistration_delay: 450,
      health_check:
    }.merge(overrides)
  end

  def health_check(overrides = {})
    {
      path: '/health',
      port: 'traffic-port',
      protocol: 'HTTP',
      interval: 30,
      healthy_threshold: 5,
      unhealthy_threshold: 5
    }.merge(overrides)
  end
end

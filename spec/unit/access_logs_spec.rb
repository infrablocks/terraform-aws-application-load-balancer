# frozen_string_literal: true

require 'spec_helper'

describe 'access logs' do
  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'does not enable access logging' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_lb')
                  .with_attribute_value([:access_logs, 0, :enabled], true))
    end
  end

  describe 'when access_logs is enabled' do
    before(:context) do
      @bucket = 'some-access-logs-bucket'
      @prefix = 'some-prefix'

      @plan = plan(role: :root) do |vars|
        vars.access_logs = {
          enabled: true,
          bucket: @bucket,
          prefix: @prefix
        }
      end
    end

    it 'enables access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value([:access_logs, 0, :enabled], true))
    end

    it 'uses the provided bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value([:access_logs, 0, :bucket], @bucket))
    end

    it 'uses the provided prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value([:access_logs, 0, :prefix], @prefix))
    end
  end
end

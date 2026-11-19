# frozen_string_literal: true

require 'spec_helper'

describe 'zonal shift' do
  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'does not enable zonal shift' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:enable_zonal_shift, false))
    end
  end

  describe 'when enable_zonal_shift is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_zonal_shift = true
      end
    end

    it 'enables zonal shift' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb')
              .with_attribute_value(:enable_zonal_shift, true))
    end
  end
end

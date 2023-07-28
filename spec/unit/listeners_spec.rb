# frozen_string_literal: true

require 'spec_helper'

describe 'listeners' do
  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'does not create any listeners' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_lb_listener'))
    end

    it 'outputs an empty map of listeners' do
      expect(@plan)
        .to(include_output_creation(name: 'listeners')
              .with_value({}))
    end
  end

  describe 'when one listener specified' do
    describe 'by default' do
      before(:context) do
        @key = 'default'
        @port = 443
        @protocol = 'HTTPS'
        @ssl_policy = 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06'
        @certificate_arn = output(role: :prerequisites, name: 'certificate_arn')
        @default_action_type = 'forward'
        @default_action_target_group_key = 'default'

        @plan = plan(role: :root) do |vars|
          vars.listeners = [
            {
              key: @key,
              port: @port,
              protocol: @protocol,
              ssl_policy: @ssl_policy,
              certificate_arn: @certificate_arn,
              default_actions: [{
                type: @default_action_type,
                target_group_key: @default_action_target_group_key
              }]
            }
          ]
          vars.target_groups = [
            {
              key: 'default',
              port: 80,
              protocol: 'HTTP',
              target_type: 'instance',
              deregistration_delay: nil,
              health_check:
                {
                  path: '/health',
                  port: 'traffic-port',
                  protocol: 'HTTP',
                  interval: 30,
                  healthy_threshold: 5,
                  unhealthy_threshold: 5
                }
            }
          ]
        end
      end

      it 'creates a listener' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .once)
      end

      it 'uses the specified port' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, @port))
      end

      it 'uses the specified protocol' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:protocol, @protocol))
      end

      it 'uses the specified SSL policy' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:ssl_policy, @ssl_policy))
      end

      it 'uses the specified certificate ARN' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:certificate_arn, @certificate_arn))
      end

      it 'uses the specified default action type' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0, :type], @default_action_type
                ))
      end
    end

    describe 'when authenticate-oidc and forward default actions provided' do
      before(:context) do
        @forward_action_type = 'forward'
        @forward_action_target_group_key = 'default'

        @authenticate_oidc_action_type = 'authenticate-oidc'
        @authenticate_oidc_action_authorization_endpoint =
          'https://example.com/authorization_endpoint'
        @authenticate_oidc_action_client_id = 'client_id'
        @authenticate_oidc_action_client_secret = 'client_secret'
        @authenticate_oidc_action_issuer = 'https://example.com'
        @authenticate_oidc_action_token_endpoint =
          'https://example.com/token_endpoint'
        @authenticate_oidc_action_user_info_endpoint =
          'https://example.com/user_info_endpoint'

        @oidc_action_authentication_request_extra_params =
          { 'user_type' => 'example' }
        @oidc_action_on_unauthenticated_request = 'authenticate'
        @oidc_action_scope = 'admin support'
        @oidc_action_session_cookie_name = 'some_random_cookie'
        @oidc_action_session_timeout = 50_000

        @plan = plan(role: :root) do |vars|
          vars.listeners = [
            {
              key: 'default',
              port: 443,
              protocol: 'HTTPS',
              ssl_policy: 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06',
              certificate_arn:
                output(role: :prerequisites, name: 'certificate_arn'),
              default_actions: [
                {
                  type: @authenticate_oidc_action_type,
                  authorization_endpoint:
                    @authenticate_oidc_action_authorization_endpoint,
                  client_id: @authenticate_oidc_action_client_id,
                  client_secret: @authenticate_oidc_action_client_secret,
                  issuer: @authenticate_oidc_action_issuer,
                  token_endpoint: @authenticate_oidc_action_token_endpoint,
                  user_info_endpoint:
                    @authenticate_oidc_action_user_info_endpoint,
                  authentication_request_extra_params:
                    @oidc_action_authentication_request_extra_params,
                  on_unauthenticated_request:
                    @oidc_action_on_unauthenticated_request,
                  scope: @oidc_action_scope,
                  session_cookie_name: @oidc_action_session_cookie_name,
                  session_timeout: @oidc_action_session_timeout
                },
                {
                  type: @forward_action_type,
                  target_group_key: @forward_action_target_group_key
                }
              ]
            }
          ]
          vars.target_groups = [
            {
              key: 'default',
              port: 80,
              protocol: 'HTTP',
              target_type: 'instance',
              deregistration_delay: nil,
              health_check:
                {
                  path: '/health',
                  port: 'traffic-port',
                  protocol: 'HTTP',
                  interval: 30,
                  healthy_threshold: 5,
                  unhealthy_threshold: 5
                }
            }
          ]
        end
      end

      it 'includes default actions in the order provided' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0, :type], @authenticate_oidc_action_type
                )
                .with_attribute_value(
                  [:default_action, 1, :type], @forward_action_type
                ))
      end

      it 'uses the provided authenticate-oidc authorization endpoint' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :authorization_endpoint],
                  @authenticate_oidc_action_authorization_endpoint
                ))
      end

      it 'uses the provided authenticate-oidc client ID' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :client_id],
                  @authenticate_oidc_action_client_id
                ))
      end

      it 'uses the provided authenticate-oidc client secret' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :client_secret],
                  matching(/^#{@authenticate_oidc_action_client_secret}$/)
                ))
      end

      it 'uses the provided authenticate-oidc issuer' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :issuer],
                  @authenticate_oidc_action_issuer
                ))
      end

      it 'uses the provided authenticate-oidc token endpoint' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :token_endpoint],
                  @authenticate_oidc_action_token_endpoint
                ))
      end

      it 'uses the provided authenticate-oidc user info endpoint' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :user_info_endpoint],
                  @authenticate_oidc_action_user_info_endpoint
                ))
      end

      it 'uses the provided authenticate-oidc extra params' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :authentication_request_extra_params],
                  @oidc_action_authentication_request_extra_params
                ))
      end

      it 'uses the provided authenticate-oidc on unauthenticated request' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :on_unauthenticated_request],
                  @oidc_action_on_unauthenticated_request
                ))
      end

      it 'uses the provided authenticate-oidc scope' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :scope],
                  @oidc_action_scope
                ))
      end

      it 'uses the provided authenticate-oidc session cookie name' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :session_cookie_name],
                  @oidc_action_session_cookie_name
                ))
      end

      it 'uses the provided authenticate-oidc session timeout' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(
                  [:default_action, 0,
                   :authenticate_oidc, 0,
                   :session_timeout],
                  @oidc_action_session_timeout
                ))
      end
    end
  end

  describe 'when many listeners specified' do
    before(:context) do
      @certificate_arn = output(role: :prerequisites, name: 'certificate_arn')

      @key1 = 'first'
      @port1 = 443
      @protocol1 = 'HTTPS'
      @ssl_policy1 = 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06'
      @default_action_type1 = 'forward'
      @default_action_target_group_key1 = 'first'

      @key2 = 'second'
      @port2 = 8443
      @protocol2 = 'HTTPS'
      @ssl_policy2 = 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06'
      @default_action_type2 = 'forward'
      @default_action_target_group_key2 = 'second'

      @listener1 = {
        key: @key1,
        port: @port1,
        protocol: @protocol1,
        ssl_policy: @ssl_policy1,
        certificate_arn: @certificate_arn,
        default_actions: [{
          type: @default_action_type1,
          target_group_key: @default_action_target_group_key1
        }]
      }
      @listener2 = {
        key: @key2,
        port: @port2,
        protocol: @protocol2,
        ssl_policy: @ssl_policy2,
        certificate_arn: @certificate_arn,
        default_actions: [{
          type: @default_action_type2,
          target_group_key: @default_action_target_group_key2
        }]
      }

      @listeners = [@listener1, @listener2]

      @plan = plan(role: :root) do |vars|
        vars.listeners = [
          @listener1,
          @listener2
        ]
        vars.target_groups = [
          {
            key: 'first',
            port: 80,
            protocol: 'HTTP',
            target_type: 'instance',
            deregistration_delay: nil,
            health_check:
              {
                path: '/health',
                port: 'traffic-port',
                protocol: 'HTTP',
                interval: 30,
                healthy_threshold: 5,
                unhealthy_threshold: 5
              }
          },
          {
            key: 'second',
            port: 8080,
            protocol: 'HTTP',
            target_type: 'instance',
            deregistration_delay: nil,
            health_check:
              {
                path: '/health',
                port: 'traffic-port',
                protocol: 'HTTP',
                interval: 30,
                healthy_threshold: 5,
                unhealthy_threshold: 5
              }
          }
        ]
      end
    end

    it 'creates each listener' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .exactly(@listeners.count).times)
    end

    it 'uses the specified ports' do
      @listeners.each do |listener|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, listener[:port]))
      end
    end

    it 'uses the specified protocols' do
      @listeners.each do |listener|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, listener[:port])
                .with_attribute_value(:protocol, listener[:protocol]))
      end
    end

    it 'uses the specified SSL policies' do
      @listeners.each do |listener|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, listener[:port])
                .with_attribute_value(:ssl_policy, listener[:ssl_policy]))
      end
    end

    it 'uses the specified certificate ARN' do
      @listeners.each do |listener|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, listener[:port])
                .with_attribute_value(
                  :certificate_arn, listener[:certificate_arn]
                ))
      end
    end

    it 'uses the specified default action types' do
      @listeners.each do |listener|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_lb_listener')
                .with_attribute_value(:port, listener[:port])
                .with_attribute_value(
                  [:default_action, 0,
                   :type], listener[:default_actions][0][:type]
                ))
      end
    end
  end

  describe 'when nil values provided for a listener' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.listeners = [
          {
            key: 'default',
            port: nil,
            protocol: nil,
            ssl_policy: nil,
            certificate_arn:
              output(role: :prerequisites, name: 'certificate_arn'),
            default_actions: [{
              type: nil,
              target_group_key: 'default'
            }]
          }
        ]
        vars.target_groups = [
          {
            key: 'default',
            port: 80,
            protocol: 'HTTP',
            target_type: 'instance',
            deregistration_delay: nil,
            health_check:
              {
                path: '/health',
                port: 'traffic-port',
                protocol: 'HTTP',
                interval: 30,
                healthy_threshold: 5,
                unhealthy_threshold: 5
              }
          }
        ]
      end
    end

    it 'creates a listener' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .once)
    end

    it 'uses 443 for the port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .with_attribute_value(:port, 443))
    end

    it 'uses HTTPS for the protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .with_attribute_value(:protocol, 'HTTPS'))
    end

    it 'uses ELBSecurityPolicy-2016-08 for the SSL policy' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .with_attribute_value(:ssl_policy, 'ELBSecurityPolicy-2016-08'))
    end

    it 'uses forward for the default action type' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_lb_listener')
              .with_attribute_value(
                [:default_action, 0, :type], 'forward'
              ))
    end
  end
end

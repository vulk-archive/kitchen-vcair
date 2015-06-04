# Encoding: UTF-8
#
# Authors:: Chris McClimans (<c@vulk.co>)
# Authors:: Taylor Carpenter (<t@vulk.co>)
#
# Copyright (C) 2015, Vulk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'benchmark'
require 'fog'
require 'kitchen'
require 'etc'
require 'socket'
require 'byebug'
require 'pp'

module Kitchen
  module Driver
    # vCloud Air driver for Kitchen.
    #
    class Vcair < Kitchen::Driver::Base
      default_config :version, 'v2'
      default_config :flavor_id, 'performance1-1'
      default_config :username, 'root'
      default_config :port, '22'
      default_config :wait_for, 600
#      default_config :no_ssh_tcp_check, false
      default_config :no_ssh_tcp_check, true
      default_config :no_ssh_tcp_check_sleep, 120
      default_config :servicenet, false
      default_config(:image_id) { |driver| driver.default_image }
      default_config(:server_name) { |driver| driver.default_name }
      default_config :networks, nil
      default_config :vcair_show_progress, false

      default_config :vcair_username do
        ENV['VCAIR_USERNAME'] 
      end

      default_config :vcair_password do
        ENV['VCAIR_PASSWORD'] 
      end

      default_config :vcair_api_host do
        ENV['VCAIR_API_HOST'] 
      end

      default_config :vcair_org do
        ENV['VCAIR_ORG'] 
      end

      # default_config :vcloud_director_username do
      #   config[:vcair_username] || ENV['VCAIR_USERNAME'] 
      # end
      #
      # default_config :vcloud_director_password do
      #   config[:vcair_password] || ENV['VCAIR_PASSWORD'] 
      # end

      # default_config :vcloud_director_api_host do
      #   config[:vcair_api_host] || ENV['VCAIR_API_HOST'] 
      # end

      # default_config :vcloud_director_org do
      #   config[:vcair_org] || ENV['VCAIR_ORG'] 
      # end

      default_config :vcair_ssh_password do
        ENV['VCAIR_SSH_PASSWORD'] 
      end

      required_config :vcair_username
      required_config :vcair_password
      required_config :vcair_api_host
      required_config :vcair_org
      required_config :image_id
      required_config :vcair_ssh_password
      #required_config :public_key_path

      def initialize(config)
        super
        Fog.timeout = config[:wait_for].to_i

        # NOTE: this is for compatibility with fog
        config[:vcloud_director_org] = config[:vcair_org] || ENV['VCAIR_ORG'] 
        config[:vcloud_director_api_host] = config[:vcair_api_host] || ENV['VCAIR_API_HOST'] 
        config[:vcloud_director_username] = config[:vcair_username] || ENV['VCAIR_USERNAME'] 
        config[:vcloud_director_password] = config[:vcair_password] || ENV['VCAIR_PASSWORD'] 
      end

      def create(state)
        server = create_server
        state[:server_id] = server.id
        info("vCloud Air instance <#{state[:server_id]}> created.")
        server.wait_for { ready? }
        puts '(server ready)'
        rackconnect_check(server) if config[:rackconnect_wait]
        state[:hostname] = hostname(server)
        state[:password] = config[:vcair_ssh_password]
        tcp_check(state)
      rescue Fog::Errors::Error, Excon::Errors::Error => ex
        raise ActionFailed, ex.message
      end


          def destroy_machine(action_handler, machine_spec, machine_options)
            server = server_for(machine_spec)
            if server && server.status != 'archive' # TODO: does Vcair do archive?
              action_handler.perform_action "destroy machine #{machine_spec.name} (#{machine_spec.location['server_id']} at #{driver_url})" do
                #NOTE: currently doing 1 vm for 1 vapp
                vapp = vdc.vapps.get_by_name(machine_spec.name)
                if vapp
                  vapp.power_off
                  vapp.undeploy
                  vapp.destroy
                else
                  Chef::Log.warn "No VApp named '#{server_name}' was found."
                end
              end
            end
            machine_spec.location = nil
            strategy = convergence_strategy_for(machine_spec, machine_options)
            strategy.cleanup_convergence(action_handler, machine_spec)
          end

      def destroy(state)
        return if state[:server_id].nil?
        begin
          vapp = vdc.vapps.get(state[:server_id])
        rescue Fog::Compute::VcloudDirector::Forbidden => e
          vapp = nil
        rescue Exception => e
          info("Rackspace instance <#{state[:server_id]}> not found!")
          byebug
        end
        if vapp
          vapp.power_off
          vapp.undeploy
          vapp.destroy
          info("Rackspace instance <#{state[:server_id]}> destroyed.")
        else
          warn("VApp <#{state[:server_id]}> not found!")
        end
        state.delete(:server_id)
        state.delete(:hostname)
      end

      def default_image
        'CentOS64-64BIT'
      end

      # Generate what should be a unique server name up to 63 total chars
      # Base name:    15
      # Username:     15
      # Hostname:     23
      # Random string: 7
      # Separators:    3
      # ================
      # Total:        63
      def default_name
        [
          instance.name.gsub(/\W/, '')[0..14],
          (Etc.getlogin || 'nologin').gsub(/\W/, '')[0..14],
          Socket.gethostname.gsub(/\W/, '')[0..22],
          Array.new(7) { rand(36).to_s(36) }.join
        ].join('-')
      end

      private

      def compute
        server_def = { provider: 'vclouddirector' } # fog driver for vcair
        opts = [:vcair_username, :vcair_password, :vcair_api_host]
        opts.each do |opt|
          # map vcair to vcloud_director fog naming
          case opt
          when :vcair_username
            username = [config[opt], config[:vcair_org]].join('@') 
            server_def[:vcloud_director_username] = username
          when :vcair_password
            server_def[:vcloud_director_password] = config[opt]
          when :vcair_api_host
            server_def[:vcloud_director_host] = config[opt]
          when :vcair_api_version
            server_def[:vcloud_director_api_version] = config[opt]
          when :vcair_show_progress
            server_def[:vcloud_director_show_progress] = config[opt]
          else
            server_def[opt] = config[opt]
          end
        end
        begin
          Fog::Compute.new(server_def)
        rescue Excon::Errors::Unauthorized => e
          error_message = "Connection failure, please check your username and password."
          Chef::Log.error(error_message)
          raise "#{e.message}. #{error_message}"
        rescue Excon::Errors::SocketError => e
          error_message = "Connection failure, please check your authentication URL."
          Chef::Log.error(error_message)
          raise "#{e.message}. #{error_message}"
        end
      end

      def create_server
        server_def = { name: config[:server_name], networks: networks }
        [:image_id, :flavor_id, :public_key_path].each do |opt|
          server_def[opt] = config[opt]
        end


        server_def[:image_name] = config[:image_id] || config[:image_name]
        #server_def[:no_passwd_lock] = true if config[:rackconnect_wait]
        clean_bootstrap_options = Marshal.load(Marshal.dump(server_def)) # Prevent destructive operations on bootstrap_options.
        bootstrap_options = clean_bootstrap_options
        bootstrap_options[:ssh_password] = config[:vcair_ssh_password]
        bootstrap_options[:name] = default_name # .gsub(/\W/,"-").slice(0..14)

        begin
          instantiate(clean_bootstrap_options)
          vapp = vdc.vapps.get_by_name(bootstrap_options[:name])
          vm = vapp.vms.find {|v| v.vapp_name == bootstrap_options[:name]}
          update_customization(clean_bootstrap_options, vm)
          if clean_bootstrap_options[:cpus]
            vm.cpu = clean_bootstrap_options[:cpus]
          end
          if clean_bootstrap_options[:memory]
            vm.memory = bootstrap_options[:memory]
          end
          update_network(clean_bootstrap_options, vapp, vm)

        rescue Excon::Errors::BadRequest => e
          response = Chef::JSONCompat.from_json(e.response.body)
          if response['badRequest']['code'] == 400
            message = "Bad request (400): #{response['badRequest']['message']}"
              Chef::Log.error(message)
          else
            message = "Unknown server error (#{response['badRequest']['code']}): #{response['badRequest']['message']}"
              Chef::Log.error(message)
          end
          raise message
        rescue Fog::Errors::Error => e
          raise e.message
        end

        vm.power_on
        yield vm if block_given?
        vm
      end

      def images
        @images ||= begin
          json_file = File.expand_path('../../../../data/images.json', __FILE__)
          JSON.load(IO.read(json_file))
        end
      end

      def tcp_check(state)
        # allow driver config to bypass SSH tcp check -- because
        # it doesn't respect ssh_config values that might be required
        # FIXME: waid_for_sshd doesn't exist
        wait_for_sshd(state[:hostname]) unless config[:no_ssh_tcp_check]
        sleep(config[:no_ssh_tcp_check_sleep]) if config[:no_ssh_tcp_check]
        puts '(ssh ready)'
      end

      def rackconnect_check(server)
        server.wait_for \
          { metadata.all['rackconnect_automation_status'] == 'DEPLOYED' }
        puts '(rackconnect automation complete)'
        server.update # refresh accessIPv4 with new IP
      end

      def hostname(server)
        # we don't trust dns yet
        server.ip_address
      end

      def networks
        base_nets = %w(
          00000000-0000-0000-0000-000000000000
          11111111-1111-1111-1111-111111111111
        )
        config[:networks] ? base_nets + config[:networks] : nil
      end


      def org
        @org ||= compute.organizations.get_by_name(config[:vcair_org])
      end

      def vdc
        if config[:vcair_vdc]
          @vdc ||= org.vdcs.get_by_name(config[:vcair_vdc])
        else
          @vdc ||= org.vdcs.first
        end
      end


      def net
        if config[:vcair_net]
          @net ||= org.networks.get_by_name(config[:vcair_net])
        else
          # Grab first non-isolated (bridged, natRouted) network
          @net ||= org.networks.find { |n| n if !n.fence_mode.match("isolated") }
        end
      end

      def template(bootstrap_options)
        # TODO: find by catalog item ID and/or NAME
        # TODO: add option to search just public and/or private catalogs
        tmpl=org.catalogs.map do |cat|
          #cat.catalog_items.get_by_name(config(:image_id))
          cat.catalog_items.get_by_name(bootstrap_options[:image_name])
        end.compact.first
        #byebug
        tmpl
      end

      def instantiate(bootstrap_options)
        begin
          #byebug
          #node_name = config_value(:chef_node_name)
          #node_name = bootstrap_options[:name]
          node_name = bootstrap_options[:name]
          template(bootstrap_options).instantiate(
            node_name,
            vdc_id: vdc.id,
            network_id: net.id,
            description: "id:#{node_name}")
          #rescue CloudExceptions::ServerCreateError => e
        rescue => e
          raise e
        end
      end

      def update_customization(bootstrap_options, server)
        ## Initialization before first power on.
        c=server.customization

        if bootstrap_options[:customization_script]
          c.script = open(bootstrap_options[:customization_script]).read
        end

        # TODO: check machine type and pick accordingly for Chef provisioning
        # password = case config_value(:bootstrap_protocol)
        #            when 'winrm'
        #              config_value(:winrm_password)
        #            when 'ssh'
        #              config_value(:ssh_password)
        #            end

        password = bootstrap_options[:ssh_password]
        # byebug
        if password
          c.admin_password =  password 
          c.admin_password_auto = false
          c.reset_password_required = false
        else
          # Password will be autogenerated
          c.admin_password_auto=true
          # API will force password resets when auto is enabled
          c.reset_password_required = true
        end

        # DNS and Windows want AlphaNumeric and dashes for hostnames
        # Windows can only handle 15 character hostnames
        # TODO: only change name for Windows!
        c.computer_name = bootstrap_options[:name] # .gsub(/\W/,"-").slice(0..14)
        c.enabled = true
        # FIXME, names ending in - don't work either
        # c.computer_name = bootstrap_options[:name].gsub(/-$/,"").slice(0..14)
        c.save
      end

      ## Vcair
      ## TODO: make work with floating_ip
      ## NOTE: current vcair networking changes require VM to be powered off
      def update_network(bootstrap_options, vapp, vm)
        ## TODO: allow user to specify network to connect to (see above net used)
        # Define network connection for vm based on existing routed network

        # Vcair inlining vapp() and vm()
        #vapp = vdc.vapps.get_by_name(bootstrap_options[:name])
        #vm = vapp.vms.find {|v| v.vapp_name == bootstrap_options[:name]}
        nc = vapp.network_config.find { |n| n if n[:networkName].match(net.name) }
        networks_config = [nc]
        section = {PrimaryNetworkConnectionIndex: 0}
        section[:NetworkConnection] = networks_config.compact.each_with_index.map do |network, i|
          connection = {
            network: network[:networkName],
            needsCustomization: true,
            NetworkConnectionIndex: i,
            IsConnected: true
          }
          ip_address      = network[:ip_address]
          ## TODO: support config options for allocation mode
          #allocation_mode = network[:allocation_mode]
          #allocation_mode = 'manual' if ip_address
          #allocation_mode = 'dhcp' unless %w{dhcp manual pool}.include?(allocation_mode)
          #allocation_mode = 'POOL'
          #connection[:Dns1] = dns1 if dns1
          allocation_mode = 'pool'
          connection[:IpAddressAllocationMode] = allocation_mode.upcase
          connection[:IpAddress] = ip_address if ip_address
          connection
        end

        ## attach the network to the vm
        nc_task = compute.put_network_connection_system_section_vapp(
          vm.id,section).body
          compute.process_task(nc_task)
      end
    end
  end
end

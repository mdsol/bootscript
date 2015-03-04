module Bootscript
  # provides built-in Chef templates and attributes
  module Chef

    # returns a map of the built-in Chef templates, in the context of erb_vars
    # The presence of :chef_validation_pem triggers the inclusion of Chef
    def self.files(erb_vars)
      if Bootscript.windows?(erb_vars)
        files_for_windows(erb_vars)
      else
        files_for_unix(erb_vars)
      end
    end

    # defines whether or not Chef support will be included in the boot script,
    # based on the presence of a certain key or keys in erb_vars
    # @param [Hash] erb_vars template vars to use for determining Chef inclusion
    # @return [Boolean] true if erb_vars has the key :chef_validation_pem
    def self.included?(erb_vars = {})
      erb_vars.has_key? :chef_validation_pem
    end

    private

    def self.files_for_unix(erb_vars)
      template_dir = "#{Bootscript::BUILTIN_TEMPLATE_DIR}/chef"
      { # built-in files
        '/usr/local/sbin/chef-install.sh' =>
          File.new("#{template_dir}/chef-install.sh.erb"),
        '/etc/chef/attributes.json'       =>
          File.new("#{template_dir}/attributes.json.erb"),
        '/etc/chef/client.d/include_json_attributes.rb' =>
          File.new("#{template_dir}/json_attributes.rb.erb"),
        '/etc/chef/client.d/ssl_config.rb' =>
          File.new("#{template_dir}/ssl_config.rb.erb"),
        '/etc/chef/client.rb'             =>
          File.new("#{template_dir}/chef_client.conf.erb"),
        # files generated from required ERB vars
        "#{erb_vars[:ramdisk_mount]}/chef/validation.pem" =>
          erb_vars[:chef_validation_pem] || '',
        "#{erb_vars[:ramdisk_mount]}/chef/encrypted_data_bag_secret" =>
          erb_vars[:chef_databag_secret] || '',
      }
    end

    def self.files_for_windows(erb_vars)
      template_dir = "#{Bootscript::BUILTIN_TEMPLATE_DIR}/chef"
      files = { # built-in files
        'chef/chef-install.ps1' =>
          File.new("#{template_dir}/chef-install.ps1.erb"),
        'chef/client.rb'        =>
          File.new("#{template_dir}/chef_client.conf.erb"),
        'chef/attributes.json'  =>
          File.new("#{template_dir}/attributes.json.erb"),
        'chef/client.d/include_json_attributes.rb' =>
          File.new("#{template_dir}/json_attributes.rb.erb"),
        'chef/client.d/ssl_config.rb' =>
          File.new("#{template_dir}/ssl_config.rb.erb"),
        # files generated from required ERB vars
        "chef/validation.pem" =>
          erb_vars[:chef_validation_pem] || '',
        "chef/encrypted_data_bag_secret" =>
          erb_vars[:chef_databag_secret] || '',
      }
      if erb_vars[:create_ramdisk]
        files.merge!(
          'chef/client.d/ramdisk_secrets.rb' =>
            File.new("#{template_dir}/ramdisk_secrets.rb.erb"))
      end
      files
    end

  end
end

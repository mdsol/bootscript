module Bootscript
  # provides built-in Ansible templates and attributes
  module Ansible

    # returns a map of the built-in Ansible templates, in the context of erb_vars
    # The presence of :tower_url triggers the inclusion of Ansible
    def self.files(erb_vars)
      if Bootscript.windows?(erb_vars)
        files_for_windows(erb_vars)
      else
        files_for_unix(erb_vars)
      end
    end

    # defines whether or not Ansible support will be included in the boot script,
    # based on the presence of a certain key or keys in erb_vars
    # @param [Hash] erb_vars template vars to use for determining Ansible inclusion
    # @return [Boolean] true if erb_vars has the key :tower_url
    def self.included?(erb_vars = {})
      erb_vars.has_key? :tower_url
    end

    private

    def self.files_for_unix(erb_vars)
      template_dir = "#{Bootscript::BUILTIN_TEMPLATE_DIR}/ansible"
      { # built-in files
        '/usr/local/sbin/ansible-install.sh' =>
            File.new("#{template_dir}/ansible-install.sh.erb"),
        '/usr/local/sbin/ansible-post-data-script.sh' =>
            File.new("#{template_dir}/ansible-post-data-script.sh.erb"),
      }
    end

    def self.files_for_windows(erb_vars)
      template_dir = "#{Bootscript::BUILTIN_TEMPLATE_DIR}/ansible"
      { # built-in files
        'ansible/ansible-install.ps1' =>
            File.new("#{template_dir}/ansible-install.ps1.erb"),
        'ansible/ansible-post-data-script.ps1' =>
            File.new("#{template_dir}/ansible-post-data-script.ps1.erb"),
      }
    end

  end
end

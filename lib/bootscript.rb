require 'logger'
require 'bootscript/version'
require 'bootscript/script'
require 'bootscript/uu_writer'
require 'bootscript/chef'
require 'bootscript/ansible'

# provides the software's only public method, generate()
module Bootscript

  # These values are interpolated into all templates, and can be overridden
  # in calls to {Bootscript#generate}
  DEFAULT_VARS = {
    platform:        :unix,         # or :windows
    create_ramdisk:  false,
    startup_command: '',  # customized by platform if chef used
    ramdisk_mount:   '',  # customized by platform, see platform_defaults
    ramdisk_size:    20,  # Megabytes
    add_script_tags: false,
    script_name:     'bootscript',  # base name of the boot script
    strip_comments:  true,
    imdisk_url:      'http://www.ltr-data.se/files/imdiskinst.exe',
    update_os:       false,
    inst_pkgs:       'bash openssl openssh-server', #list of packages you want upgraded
    curl_options:    '',
    bash_options:    '',
    use_chef:        false,
    use_ansible:     false,
    package_update:  true
  }

  # Generates the full text of a boot script based on the supplied
  # template_vars and data_map. If no optional destination is supplied,
  # the full text is returned as a String. Otherwise, the text is
  # written to the destination using write(), and the number of bytes
  # written is returned.
  def self.generate(template_vars = {}, data_map = {}, destination = nil)
    script = Bootscript::Script.new(template_vars[:logger])
    script.data_map = data_map
    script.generate(template_vars, destination)
  end

  # Returns true if the passed Hash of erb_vars indicate a
  # Windows boot target
  def self.windows?(erb_vars)
    (erb_vars[:platform] || '').to_s.downcase == 'windows'
  end

  # Returns a slightly-modified version of the default Ruby Logger
  # @param output [STDOUT, File, etc.] where to write the logs
  # @param level [DEBUG|INFO|etc.] desired minimum severity
  # @return [Logger] a standard Ruby Logger with a nicer output format
  def self.default_logger(output = nil, level = Logger::FATAL)
    logger = ::Logger.new(output || STDOUT)
    logger.sev_threshold = level
    logger.formatter = proc {|lvl, time, prog, msg|
      "#{lvl} #{time.strftime '%Y-%m-%d %H:%M:%S %Z'}: #{msg}\n"
    }
    logger
  end

  def self.powershell_cmd(script_path, script_log)
    %Q{PowerShell -Command "& {#{script_path}}" > #{script_log} 2>&1}
  end

  # Returns the passed Hash of template vars, merged over a set of
  # computed, platform-specific default variables
  def self.merge_platform_defaults(vars)
    defaults = DEFAULT_VARS.merge(vars)
    defaults[:use_chef] = Chef::included?(defaults)
    defaults[:use_ansible] = Ansible::included?(defaults)
    startup_cmd = []
    if defaults[:platform].to_s == 'windows'
      defaults[:ramdisk_mount]      = 'R:'
      defaults[:script_name]        = 'bootscript.ps1'
      if defaults[:use_ansible]
        startup_cmd << powershell_cmd(
            'C:/ansible/ansible-install.ps1',
            'C:/ansible/bootscript_setup.log')
        defaults[:tower_post_data_file] = 'C:/ansible/ansible-post-data.txt'
      end
      if defaults[:use_chef]
        startup_cmd << powershell_cmd(
            'C:/chef/chef-install.ps1',
            'C:/chef/bootscript_setup.log')
      end
      if startup_cmd.size > 0
        defaults[:startup_command]  = startup_cmd.join(' ; ')
      end
    else # unix! the only way it should be...
      defaults[:ramdisk_mount]      = '/etc/secrets'
      defaults[:script_name]        = 'bootscript.sh'
      if defaults[:use_chef]
        startup_cmd << 'chef-install.sh'
      end
      if defaults[:use_ansible]
        startup_cmd << 'ansible-install.sh'
        defaults[:tower_post_data_file] = '/tmp/ansible-post-data'
      end
      if startup_cmd.size > 0
        defaults[:startup_command]  = startup_cmd.join(' && ')
      end
    end
    defaults[:startup_failed_command] ||= ''
    defaults[:startup_command] ||= 'echo "No bootstrap requested"'
    defaults.merge(vars)  # return user vars merged over platform defaults
  end

  BUILTIN_TEMPLATE_DIR  = "#{File.dirname(__FILE__)}/templates"
  UNIX_TEMPLATE         = "#{BUILTIN_TEMPLATE_DIR}/bootscript.sh.erb"
  WINDOWS_TEMPLATE      = "#{BUILTIN_TEMPLATE_DIR}/bootscript.ps1.erb"

end

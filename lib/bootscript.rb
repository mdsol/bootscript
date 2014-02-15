require 'logger'
require 'bootscript/version'

# provides the software's only public method, generate()
module Bootscript

  # These values are interpolated into all templates, and can be overridden
  # in calls to {Bootscript#generate}
  DEFAULT_VARS = {
    platform:       :unix,          # or :windows
    create_ramdisk: false,
    startup_command: '',  # customized by platform if chef used
    ramdisk_mount:  '',   # customized by platform, see platform_defaults
    ramdisk_size:   20,   # Megabytes
    add_script_tags: true,
    script_name:    's3_bootstrap', # base name of the S3 boot script
    strip_comments: true,
    imdisk_url:     'http://www.ltr-data.se/files/imdiskinst.exe',
  }


end

List of Template Variables
================
Here is a list of all the keys that a call to `Bootscript.generate` will check for, and how they affect the gem's behavior.


Main settings
----------------
* `:platform` - when set to `:unix` (default), the gem produces a Bash script as output. When set to `:windows`, the gem produces Powershell wrapped in a Batch script.
* `:startup_command` - The command to be executed after the archive is extracted. If Chef support is enabled (by setting `chef_validation_pem`), this value defaults to a platform-specific command that invokes the built-in Chef support. Otherwise, it defaults to `nil`, and no startup command is executed. In either case, it can be overridden.
* `:update_os` - If `true`, will attempt to upgrade all the operating system packages. Defaults to `false`. _(Debian/Ubuntu only for now.)_
* `:add_script_tags` - _(Windows only.)_ When set to `true`, encloses the output in `<SCRIPT>...</SCRIPT>` XML tags, usually required for AWS.


Chef settings
----------------
The Chef-based examples in the README illustrate the included Chef support.
* `:chef_validation_pem` - When set to any non-nil value, enables the built-in Chef support. The value must be the key data itself, so read it into memory first.
* `:chef_databag_secret` - The secret used to decrypt the Chef org's encrypted data bag items.
* `:chef_attributes` - a Hash of Chef attributes that is read as `node[chef_client][config]` by the [Opscode chef-client cookbook][1]. This is where you specify your `node_name` (if desired), `chef_server_url`, `validation_client_name`, etc. *Always use strings for chef attribute keys, not symbols!*


Ansible settings
----------------
The Ansible-based examples in the README illustrate the included Ansible support.
* `:tower_url` - When set to any non-nil value, enables the built-in Ansible support. The value is the URL at which Ansible Tower listens for requests to run playbooks.
* `:tower_post_data_script` - The path to the script that will generate the body of the POST request made to the tower_url.
* `:tower_post_data_file` - The path to the file containing the POST request made to the tower_url.


RAMdisk settings
----------------
* `:create_ramdisk` - Setting this to `true` generates a bootscript that creates a RAMdisk of a configurable size and at a configurable filesystem location. This happens even before the archive is unpacked, so you can extract files into the RAMdisk.
* `:ramdisk_mount` - The filesystem location where the RAMdisk is mounted. (defaults to `false`)
* `:ramdisk_size` - Size, in Megabytes, of the RAMdisk. (defaults to 20)


--------
[1]:https://github.com/opscode-cookbooks/chef-client

Bootscript
================
Constructs a self-extracting archive, wrapped in a Bash script (or Windows batch script), for securely initializing cloud systems.

  *BETA VERSION - needs more functional testing and broader OS support*

----------------
What is it?
----------------
The bootscript gem enables simple creation of a self-extracting "TAR archive within a Bash script", which can be composed from any set of binary or text files -- including support for ERB templates. Any Hash of Ruby values can be interpolated into these templates when they are rendered, and the resulting "boot script" (complete with the base64-encoded archive at the end) can be invoked on nearly any Unix or Windows system to:

* create a RAMdisk for holding the archive contents, which are presumably secrets (this step is optional, and does not yet work on Windows)
* extract the archived files
* delete itself
* execute a user-specified command for further configuration

An extra, optional submodule is also supplied that leverages the above process to install Chef (omnibus), assign arbitrary node attributes (using the same Hash mentioned above), and kick off convergence for a given run list.


----------------
Why is it?
----------------
* makes specification of complex, cross-platform boot data simple and portable.
* simplifies initial Chef setup
* enables an initial request to a Url for bootstrapping (as for Ansible)

----------------
Where is it? (Installation)
----------------
Install the gem and its dependencies from RubyGems:

    gem install bootscript


----------------
How is it [done]? (Usage)
----------------
Call the gem's main public method: `Bootscript.generate()`. It accepts a Hash of template variables as its first argument, which is passed directly to any ERB template files as they render. All the data in the Hash is available to the templates, but some of the key-value pairs also control the gem's rendering behavior, as demonstrated in the following examples. (There's also a [list of such variables](ERB_VARS.md).)


### Simplest - make a RAMdisk

    require 'bootscript'
    script = Bootscript.generate(
      create_ramdisk:    true,                # default mount is /etc/secrets
      startup_command:  'df -h /etc/secrets'  # show the RAMdisk's free space
    )
    puts "Now run this as root on any unix node that has `bash` installed:"
    puts script


### Simple - render and install a bash script, then run it

To include some files inside the script's archive, create a "data map", which is a Hash that maps locations on the boot target's filesystem to the values that will be written there when the script is run. The following example generates a script that, when executed, writes some text into the file `/root/hello.sh`.

    # Define a simple shell script, to be written to the node's filesystem:
    data_map = {'/root/hello.sh' => 'echo Hello, <%= my_name %>.'}
    puts Bootscript.generate({
        my_name:          ENV['USER'],          # evaluated now, at generation
        startup_command:  'sh /root/hello.sh',  # run on the node, after unarchiving
      }, data_map
    )

_(Can you guess what it will print on the node that runs the script?)_


### Chef support, using the included templates (single node)

The software's Chef support includes some predefined template files that will install the Chef client sofware, and then kick off the convergence process. These templates are automatically included into the boot script when you pass a `:chef_validation_pem` to the `generate()` method, so no data map is required for this example.

The two Chef secrets are passed directly to `generate`, so they should be read from the filesystem if necessary...

    VALIDATION_CERT = File.read "#{ENV['HOME']}/.chef/myorg-validator.pem"
    DATABAG_SECRET = File.read "#{ENV['HOME']}/.chef/myorg-databag-secret.txt"

    require 'uuid'                                    # Make some unique boot data
    NODE_UUID = UUID.generate                         # for just this one node...
    puts Bootscript.generate(
      logger:               Logger.new(STDOUT),       # Monitor progress
      create_ramdisk:       true,                     # make a RAMdisk
      chef_validation_pem:  VALIDATION_CERT,          # the data, not the path!
      chef_databag_secret:  DATABAG_SECRET,           # same here - the secret data
      chef_attributes: {    # ALWAYS USE STRINGS FOR CHEF ATTRIBUTE KEYS!
        'run_list' => 'role[my_app_server]',
        'chef_client' => {
          'config' => {
            'node_name' => "myproject-myenv-#{NODE_UUID}",
            'chef_server_url' => "https://api.opscode.com/organizations/myorg",
            'validation_client_name' => "myorg-validator",
          }
        }
      }
    )


The validation certificate and data bag secrets will be saved in a `chef` directory below the RAMdisk mount point, then symlinked into `/etc/chef`. You should use this technique for all the files you put into the `data_map` that contain secrets!

### Chef support, with the node name determined by the node

This is just like the previous example, only first you create a ruby file that will run on the node at boot time, to compute the node name. This can also be a template, like `/tmp/set_node_name.rb.erb`:

    unless node_name
      # filled in at publish() time by the bootstrap gem
      name = '<%= project %>.<%= stage %>.<%= tier %>'
      require 'ohai'
      ohai = Ohai::System.new
      ohai.all_plugins
      if ohai[:ec2] && ohai[:ec2][:instance_id]
        name = "#{name}.#{ohai[:ec2][:instance_id]}"
      else
        name = "#{name}.#{rand(2**(0.size * 8 -2) -1)}"
      end
      puts "Setting node name to #{name}..."
      node_name name
    end

Now tell the boot script to put the ruby file where chef-client will pick it up (thanks, Opscode!). Note that when including an ERB file into the boot archive, the value in the data map should be an existing Ruby File object, not a String:

    data_map = {
      '/etc/chef/client.d/set_node_name.rb' => File.new("/tmp/set_node_name.rb.erb")
    }

Finally, generate *without* an explicit node name, but filling in the other values that are known at the time. Don't forget to pass the data map as the second argument to `generate()`.

    PROJECT, STAGE, TIER = 'myapp', 'testing', 'db'
    script = Bootscript.generate({
      project:              PROJECT,  # As before, these values are rendered
      stage:                STAGE,    # into the above ruby template.
      tier:                 TIER,
      chef_attributes: {
        'run_list' => 'role[my_app_server]',
        'chef_client' => {            # NOTE - no node_name passed here,
          'config' => {               # but the rest is the same...
            'chef_server_url' => "https://api.opscode.com/organizations/myorg",
            'validation_client_name' => "myorg-validator",
          }
        }
      },
      chef_validation_pem:  VALIDATION_CERT,
      chef_databag_secret:  DATABAG_SECRET,
    }, data_map)


### Ansible support

The software's Ansible support is triggered when you pass a `:tower_host_config_key` to the `generate()` method. Also
required is `:tower_url`, used to make the request to Ansible Tower.

    puts Bootscript.generate(
      logger:                 Logger.new(STDOUT),          # Monitor progress
      tower_host_config_key:  'your-config-key',           # Obtain from Ansible Tower administrators
      tower_url:              'https://tower-host.foo.com' # ... likewise
    )


### Using Chef and Ansible together

The code is written so that if `generate()` receives both `:chef_validation_pem` and `:tower_host_config_key` parameters,
installers for both Chef and Ansible will be created and executed. The installer for Chef will be executed first. Either
of these is complicated enough, so using just one seems wise. That said, one may need to switch from one to the other,
and having both available may assist in that transition.

----------------
*Known Limitations / Bugs*
----------------
* bash and tar are required on Unix boot targets
* Powershell is required on Windows boot targets
* bash, tar and uudecode are required to run the tests


----------------
Who is it? (Contribution)
----------------
This Gem was created at [Medidata][] by Benton Roberts _(broberts@mdsol.com)_

The project is still in its early stages. Helping hands are appreciated.

1) Install project dependencies.

    gem install rake bundler

2) Fetch the project code and bundle up...

    git clone https://github.com/mdsol/bootscript.git
    cd bootscript
    bundle

3) Run the tests:

    bundle exec rake

4) Autotest while you work:

    bundle exec autotest


--------
[Medidata]: http://mdsol.com

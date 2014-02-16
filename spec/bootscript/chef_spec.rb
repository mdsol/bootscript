require 'bootscript'
include Bootscript

describe Chef do

  describe :files do
    context "given a set of ERB template vars" do
      erb_vars = {
        ramdisk_mount:        '/mount/myramdisk',
        chef_validation_pem:  'MYPEM',
        chef_databag_secret:  'SECRET',
      }
      it "returns a Hash mapping locations on the boot target to local data" do
        Chef.files(erb_vars).should be_a Hash
      end
      it "maps the Chef Validation data into place on the target's RAMdisk" do
        Chef.files(erb_vars)[
          "#{erb_vars[:ramdisk_mount]}/chef/validation.pem"
        ].should be erb_vars[:chef_validation_pem]
      end
      it "maps the Chef data bag secret into place on the target's RAMdisk" do
        Chef.files(erb_vars)[
          "#{erb_vars[:ramdisk_mount]}/chef/encrypted_data_bag_secret"
        ].should be erb_vars[:chef_databag_secret]
      end
    end
  end

  describe :included? do
    desired_key = :chef_validation_pem
    context "given a set of ERB template vars with key :#{desired_key}" do
      it "returns true" do
        Chef.included?(chef_validation_pem: 'SOME DATA').should be true
      end
    end
    context "given a set of ERB template vars without key :#{desired_key}" do
      it "returns false" do
        Chef.included?({}).should be false
      end
    end
    context "given nothing" do
      it "returns false" do
        Chef.included?().should be false
      end
    end
  end

end

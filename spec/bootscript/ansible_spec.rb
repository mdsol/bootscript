require 'bootscript'
include Bootscript

describe Ansible do

  describe :files do
    context "given a set of ERB template vars" do
      erb_vars = {
        tower_url: 'https://foo.imedidata.net'
      }
      it "returns a Hash mapping locations on the boot target to local data" do
        expect(Ansible.files(erb_vars)).to be_a Hash
      end
      it "maps the Chef Validation data into place on the target's RAMdisk" do
        expect(Ansible.files(erb_vars).keys.select { |k| k =~ /ansible-install/ }.size).to eq(1)
      end
    end
  end

  describe :included? do
    desired_key = :tower_url
    context "given a set of ERB template vars with key :#{desired_key}" do
      it "returns true" do
        expect(Ansible.included?(tower_url: 'https://foo.imedidata.net')).to be true
      end
    end
    context "given a set of ERB template vars without key :#{desired_key}" do
      it "returns false" do
        expect(Ansible.included?({})).to be false
      end
    end
    context "given nothing" do
      it "returns false" do
        expect(Ansible.included?()).to be false
      end
    end
  end

end

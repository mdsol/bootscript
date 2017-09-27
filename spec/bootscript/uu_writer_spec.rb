require 'bootscript'
include Bootscript # for brevity

describe UUWriter do

  #### TEST PUBLIC INSTANCE MEMBER VARIABLES

  it "exposes a the number of bytes written as an integer" do
    expect(UUWriter.new(nil)).to respond_to(:bytes_written)
    expect(UUWriter.new(nil).bytes_written).to be_a Fixnum
  end

  #### TEST PUBLIC METHODS

  describe :initialize do
    it "sets bytes_written to zero" do
      expect(UUWriter.new(nil).bytes_written).to eq 0
    end
  end

  describe :write do
    it "writes the uuencoded version of its argument to its output member" do
      destination = StringIO.open("", 'w')
      UUWriter.new(destination).write("Encode me!")
      destination.close
      expect(destination.string).to eq ["Encode me!"].pack('m')
    end
  end

end

require 'bootscript'
include Bootscript # for brevity

describe UUWriter do

  #### TEST PUBLIC INSTANCE MEMBER VARIABLES

  it "exposes a the number of bytes written as an integer" do
    UUWriter.new(nil).should respond_to(:bytes_written)
    UUWriter.new(nil).bytes_written.should be_a Fixnum
  end

  #### TEST PUBLIC METHODS

  describe :initialize do
    it "sets bytes_written to zero" do
      UUWriter.new(nil).bytes_written.should == 0
    end
  end

  describe :write do
    it "writes the uuencoded version of its argument to its output member" do
      destination = StringIO.open("", 'w')
      UUWriter.new(destination).write("Encode me!")
      destination.close
      destination.string.should == ["Encode me!"].pack('m')
    end
  end

end

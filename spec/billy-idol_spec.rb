require_relative '../init'

describe Release do
  it "passes the configuration to Releaser" do
    stub_config_file

    expect(Releaser).to receive(:new).with("config" => { "key" => "value" }).and_return(Anything.new)

    Release.new.index
  end

  it "runs the releaser" do
    stub_config_file
    fake_releaser = double

    expect(fake_releaser).to receive(:result)
    expect(fake_releaser).to receive(:run)
    expect(Releaser).to receive(:new).and_return(fake_releaser)

    Release.new.index
  end

  it "returns the result of Releaser" do
    stub_config_file

    Releaser.any_instance.stub(:result).and_return(:foo)

    Release.new.index.should == :foo
  end

  it "quits if there is no configuration file" do
    stub_config_file_missing

    expect(Releaser).not_to receive(:new)

    Release.new.index.should == 1
  end

  private

  def stub_config_file
    home = ENV["HOME"]
    example_config = "config:\n  key: value\n"
    File.stub(:read).with("#{home}/.billy_idol.yml").and_return(example_config)
  end

  def stub_config_file_missing
    home = ENV['HOME']
    File.stub(:read).with("#{home}/.billy_idol.yml").and_raise(Errno::ENOENT)
  end

  class Anything
    def method_missing(*)
      self.class.new
    end
  end
end

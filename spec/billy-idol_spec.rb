require_relative '../init'

describe Heroku::Command::Release do
  it "passes the configuration to Releaser" do
    stub_config_file

    expect(Releaser).to receive(:new).with("config" => { "key" => "value" }).and_return(Anything.new)

    Heroku::Command::Release.new.index
  end

  it "returns the result of Releaser" do
    stub_config_file

    Releaser.any_instance.stub(:result).and_return(:foo)

    Heroku::Command::Release.new.index.should == :foo
  end

  it "quits if there is no configuration file" do
    stub_config_file_missing

    expect(Releaser).not_to receive(:new)

    Heroku::Command::Release.new.index.should == 1
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

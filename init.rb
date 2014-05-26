require_relative 'releaser'
require 'psych'

begin
  require 'platform-api'
rescue LoadError
  system('gem install platform-api')
  require 'platform-api'
end



def test?
  File.basename($PROGRAM_NAME) == "rspec"
end

require "heroku/command/base" unless test?

module Heroku
  module Command
    class Base
    end
  end
end

# Release stuff to Heroku.
#
class Heroku::Command::Release < Heroku::Command::Base
  # release
  #
  # Release.
  #

  EXIT_ERROR = 1

  def index
    releaser = Releaser.new(config)
    releaser.run
    releaser.result
  rescue Errno::ENOENT
    print_error_message
    EXIT_ERROR
  end

  private

  def config
    yml = File.read(configuration_path)
    config = Psych.load(yml)
  end

  def configuration_path
    "#{ENV['HOME']}/.billy_idol.yml"
  end

  def print_error_message
    puts "No configuration file at #{configuration_path}" unless test?
  end
end

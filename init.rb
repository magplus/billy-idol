#require "heroku/command/base"

# Remove the following and uncomment the above to make it "usable" as Heroku plugin again.

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
  def index
    result = compose Steps.new Quitter do
      successful_action
      failing_action
      other_failing_action
    end

    puts "Result class #{result.class}"
    puts "We finished with error code #{result.error_code}"
  end

  private

  def compose object, &block
    Class.new BasicObject do
      attr_reader :state

      def self.run object, &block
        runner = new object
        runner.instance_eval &block
      end

      def initialize starting_object
        @state = starting_object
      end

      def method_missing m, *args, &block
        @state = state.send m, *args, &block
        self
      end
    end.run(object, &block).state
  end
end

class Steps < Struct.new :or_else_handler
  def error_code
    0
  end

  def successful_action
    with "It didn't work" do
      # Something that went well so we don't show the message
      true
    end
  end

  def failing_action
    with "We quit because the user chose to quit" do
      # Ask the user to quit and it does choose to quit
      false
    end
  end

  def other_failing_action
    with "Will never be reached" do
      # We failed again for some reason
      false
    end
  end

  private

  def with message, &block
    if yield
      self
    else
      or_else_handler.new message
    end
  end
end

class Quitter
  def initialize message
    puts message
  end

  def error_code
    1
  end

  def method_missing(*)
    self
  end
end

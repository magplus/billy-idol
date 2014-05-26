require 'helper'
require 'stringio'

class CLITest < MiniTest::Unit::TestCase
  include ExconHelper

  # CLI.run displays usage information when no arguments are provided.
  def test_run_without_arguments
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command1 = Heroics::Command.new(
      'cli', schema.resource('resource').link('list'), client, output)
    command2 = Heroics::Command.new(
      'cli', schema.resource('resource').link('info'), client, output)
    cli = Heroics::CLI.new('cli', {'resource:list' => command1,
                                   'resource:info' => command2}, output)
    cli.run
    expected = <<-USAGE
Usage: cli <command> [<parameter> [...]] [<body>]

Help topics, type "cli help <topic>" for more details:

  resource:info    Show a sample resource
  resource:list    Show all sample resources
USAGE
    assert_equal(expected, output.string)
  end

  # CLI.run displays usage information when the help command is specified.
  def test_run_with_help_command
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command1 = Heroics::Command.new(
      'cli', schema.resource('resource').link('list'), client, output)
    command2 = Heroics::Command.new(
      'cli', schema.resource('resource').link('info'), client, output)
    cli = Heroics::CLI.new('cli', {'resource:list' => command1,
                                   'resource:info' => command2}, output)
    cli.run('help')
    expected = <<-USAGE
Usage: cli <command> [<parameter> [...]] [<body>]

Help topics, type "cli help <topic>" for more details:

  resource:info    Show a sample resource
  resource:list    Show all sample resources
USAGE
    assert_equal(expected, output.string)
  end

  # CLI.run displays command-specific help when a command name is included
  # with the 'help' command.
  def test_run_with_help_command_and_explicit_command_name
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command1 = Heroics::Command.new(
      'cli', schema.resource('resource').link('list'), client, output)
    command2 = Heroics::Command.new(
      'cli', schema.resource('resource').link('info'), client, output)
    cli = Heroics::CLI.new('cli', {'resource:list' => command1,
                                   'resource:info' => command2}, output)
    cli.run('help', 'resource:info')
    expected = <<-USAGE
Usage: cli resource:info <uuid_field>

Description:
  Show a sample resource
USAGE
    assert_equal(expected, output.string)
  end

  # CLI.run displays an error message when no commands have been registered.
  def test_run_without_commands
    output = StringIO.new
    cli = Heroics::CLI.new('cli', {}, output)
    cli.run('help')
    assert_equal('No commands are available.', output.string)
  end

  # CLI.run displays an error message when an unknown command name is used.
  def test_run_with_unknown_name
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command = Heroics::Command.new(
      'cli', schema.resource('resource').link('list'), client, output)
    cli = Heroics::CLI.new('cli', {'resource:list' => command}, output)
    cli.run('unknown:command')
    assert_equal("There is no command called 'unknown:command'.\n",
                 output.string)
  end

  # CLI.run runs the command matching the specified name.
  def test_run_with_dashed_command_name
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command = Heroics::Command.new(
      'cli', schema.resource('resource').link('identify_resource'), client,
      output)
    cli = Heroics::CLI.new('cli', {'resource:identify-resource' => command},
                           output)

    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    Excon.stub(method: :get) do |request|
      assert_equal("/resource/#{uuid}", request[:path])
      Excon.stubs.pop
      {status: 200}
    end

    cli.run('resource:identify-resource', uuid)
    assert_equal('', output.string)
  end

  # CLI.run runs the resource matching the specified name.
  def test_run_with_dashed_resource_name
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command = Heroics::Command.new(
      'cli', schema.resource('another-resource').link('list'), client, output)
    cli = Heroics::CLI.new('cli', {'another-resource:list' => command},
                           output)

    result = {'Hello' => 'World!'}
    Excon.stub(method: :get) do |request|
      assert_equal("/another-resource", request[:path])
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    cli.run('another-resource:list')
    assert_equal(MultiJson.dump(result, pretty: true) + "\n", output.string)
  end

  # CLI.run runs the command matching the specified name and passes parameters
  # to it.
  def test_run_with_parameters
    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    client = Heroics::client_from_schema(schema, 'https://example.com')
    output = StringIO.new
    command = Heroics::Command.new(
      'cli', schema.resource('resource').link('update'), client, output)
    cli = Heroics::CLI.new('cli', {'resource:update' => command}, output)

    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    result = {'Goodbye' => 'Universe!'}
    Excon.stub(method: :patch) do |request|
      assert_equal("/resource/#{uuid}", request[:path])
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(body, MultiJson.load(request[:body]))
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    cli.run('resource:update', uuid, body)
    assert_equal(MultiJson.dump(result, pretty: true) + "\n", output.string)
  end
end

class CLIFromSchemaTest < MiniTest::Unit::TestCase
  include ExconHelper

  # cli_from_schema returns a CLI generated from the specified schema.
  def test_cli_from_schema
    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    result = {'Goodbye' => 'Universe!'}
    Excon.stub(method: :patch) do |request|
      assert_equal("/resource/#{uuid}", request[:path])
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(body, MultiJson.load(request[:body]))
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    output = StringIO.new
    cli = Heroics.cli_from_schema('cli', output, schema, 'https://example.com')
    cli.run('resource:update', uuid, body)
    assert_equal(MultiJson.dump(result, pretty: true) + "\n", output.string)
  end

  # cli_from_schema returns a CLI that can make requests to APIs mounted under
  # a prefix, such as http://example.com/api, for example.
  def test_client_from_schema_with_url_prefix
    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    result = {'Goodbye' => 'Universe!'}
    Excon.stub(method: :patch) do |request|
      assert_equal("/api/resource/#{uuid}", request[:path])
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(body, MultiJson.load(request[:body]))
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    output = StringIO.new
    cli = Heroics.cli_from_schema('cli', output, schema,
                                  'https://example.com/api')
    cli.run('resource:update', uuid, body)
    assert_equal(MultiJson.dump(result, pretty: true) + "\n", output.string)
  end

  # cli_from_schema optionally accepts custom headers to pass with every
  # request made by the generated CLI.
  def test_cli_from_schema_with_custom_headers
    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    result = {'Goodbye' => 'Universe!'}
    Excon.stub(method: :patch) do |request|
      assert_equal('application/vnd.heroku+json; version=3',
                   request[:headers]['Accept'])
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    schema = Heroics::Schema.new(SAMPLE_SCHEMA)
    output = StringIO.new
    cli = Heroics.cli_from_schema(
      'cli', output, schema, 'https://example.com',
      default_headers: {'Accept' => 'application/vnd.heroku+json; version=3'})
    cli.run('resource:update', uuid, body)
    assert_equal(MultiJson.dump(result, pretty: true) + "\n", output.string)
  end
end

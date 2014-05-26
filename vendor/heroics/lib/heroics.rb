require 'base64'
require 'erubis'
require 'excon'
require 'moneta'
require 'multi_json'
require 'uri'
require 'zlib'

# Heroics is an HTTP client for an API described by a JSON schema.
module Heroics
end

require 'heroics/version'
require 'heroics/errors'
require 'heroics/naming'
require 'heroics/link'
require 'heroics/resource'
require 'heroics/client'
require 'heroics/schema'
require 'heroics/command'
require 'heroics/cli'
require 'heroics/client_generator'

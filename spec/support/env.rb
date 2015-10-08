require "nenv"
require "dotenv"

# Default to `pwd`/.env-* ( whatever is in the current directory )
# Otherwise take the `.env-*` from the gem itself.
unless env = Nenv("celluloid").config_file
  env = Nenv.ci? ? ".env-ci" : ".env-dev"
  unless File.exist?(env)
    env = File.expand_path("../../../#{env}", __FILE__)
  end
end

Dotenv.load!(env) rescue nil # If for some reason no .env-* files are available at all, use defaults.

module Specs
  class << self
    def env
      @env ||= Nenv("celluloid_specs")
    end
  end
end

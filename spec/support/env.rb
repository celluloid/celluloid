require "nenv"
require "dotenv"

Dotenv.load!(Nenv("celluloid").config_file || (Nenv.ci? ? ".env-ci" : ".env-dev"))

module Specs
  class << self
    def env
      @env ||= Nenv("celluloid_specs")
    end
  end
end

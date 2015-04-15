require "nenv"
require "dotenv"
Dotenv.load!(Nenv("celluloid").config_file || (Nenv.ci? ? ".env-ci" : ".env-dev"))

module Specs
  def self.env
    @env ||= Nenv("celluloid_specs")
  end

  def self.configure(config)
    if Specs.split_logs?
      config.log_split_dir = File.expand_path("../../log/#{DateTime.now.iso8601}", __FILE__)
      config.log_split_module = Specs
    end
  end
end

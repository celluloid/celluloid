require 'rake'
require 'bundler'

SUBPROJECTS = %w(celluloid celluloid-io celluloid-zmq)
RETRIES     = 3
TIMEOUT     = 300

task :default do
  SUBPROJECTS.each do |project|
    Bundler.with_clean_env do
      Dir.chdir(project) do
        sh 'bundle'

        success = false
        RETRIES.times do
          success = system('bundle exec rake spec')
          break if success
        end

        raise "ERROR: #{project} failed to build #{RETRIES} times" unless success
      end
    end
  end
end

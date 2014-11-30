require 'rake'
require 'bundler'
require 'timeout'

SUBPROJECTS = %w(celluloid celluloid-io celluloid-zmq)
RETRIES     = 5
TIMEOUT     = 180

task :default do
  SUBPROJECTS.each do |project|
    Bundler.with_clean_env do
      Dir.chdir(project) do
        sh 'bundle install --retry=3'

        success = false
        RETRIES.times do
          success = begin
            timeout(TIMEOUT) do
              system('bundle exec rake spec')
            end
          rescue Timeout::Error
            false
          end

          break if success
        end

        raise "ERROR: #{project} failed to build #{RETRIES} times" unless success
      end
    end
  end
end

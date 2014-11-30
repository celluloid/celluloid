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
        sh 'bundle exec rake spec'
      end
    end
  end
end

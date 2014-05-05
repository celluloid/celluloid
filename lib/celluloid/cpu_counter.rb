require 'rbconfig'

module Celluloid
  module CPUCounter
    def self.cores
      @cores ||= count_cores
    end

  private

    def self.count_cores
      result = ENV['NUMBER_OF_PROCESSORS']
      return Integer(result, 10) if result

      result = 
        case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
        when 'darwin'
          `/usr/sbin/sysctl -n hw.ncpu`
        when /bsd|dragonfly/
          `/sbin/sysctl -n hw.ncpu`
        when 'linux'
          begin
            return ::IO.read('/sys/devices/system/cpu/present').split('-').last.to_i+1
          rescue Errno::ENOENT
            return Dir["/sys/devices/system/cpu/cpu*"].select { |n| n=~/cpu\d+/ }.count
          end
        end

      result && Integer(result.to_s[/\d+/], 10)
    end
  end
end

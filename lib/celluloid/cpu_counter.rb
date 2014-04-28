require 'rbconfig'

module Celluloid
  module CPUCounter
    def self.cores
      @cores ||= count_cores
    end

  private

    def self.count_cores
      case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
      when 'darwin'
        @cores = Integer(`/usr/sbin/sysctl hw.ncpu`[/\d+/])
      when 'linux'
        @cores = if File.exists?("/sys/devices/system/cpu/present")
                   File.read("/sys/devices/system/cpu/present").split('-').last.to_i+1
                 else
                   Dir["/sys/devices/system/cpu/cpu*"].select { |n| n=~/cpu\d+/ }.count
                 end
      when 'mingw', 'mswin', 'cygwin'
        @cores = Integer(ENV["NUMBER_OF_PROCESSORS"][/\d+/])
      when 'freebsd'
        @cores = Integer(`sysctl hw.ncpu`[/\d+/])
      else
        @cores = nil
      end
    rescue => ex
      if ENV['CELLULOID_IGNORE_CORE_COUNTING_ERRORS'] == 'true'
        $stderr.puts(ex.message + "; ignoring and setting cores to nil")
        @cores = nil
      else
        raise 
      end
    end

  end
end



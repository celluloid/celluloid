require 'rbconfig'

module Celluloid
  module CPUCounter
    case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
    when 'darwin'
      @cores = Integer(`/usr/sbin/sysctl hw.ncpu`[/\d+/])
    when 'linux'
      @cores = if File.exists?("/sys/devices/system/cpu/present")
        File.read("/sys/devices/system/cpu/present").split('-').last.to_i+1
      else
        Dir["/sys/devices/system/cpu/cpu*"].select { |n| n=~/cpu\d+/ }.count
      end
    when 'mingw', 'mswin'
      @cores = Integer(ENV["NUMBER_OF_PROCESSORS"][/\d+/])
    else
      @cores = nil
    end

    def self.cores; @cores; end
  end
end



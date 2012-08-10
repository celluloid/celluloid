require 'rbconfig'

module Celluloid
  module CPUCounter
    case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
    when 'darwin'
      @cores = Integer(`sysctl hw.ncpu`[/\d+/])
    when 'linux'
      @cores = File.read("/proc/cpuinfo").scan(/core id\s+: \d+/).uniq.size
    when 'mingw', 'mswin'
      @cores = Integer(`SET NUMBER_OF_PROCESSORS`[/\d+/])
    else
      @cores = nil
    end

    def self.cores; @cores; end
  end
end

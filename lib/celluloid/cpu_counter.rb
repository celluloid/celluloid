require 'rbconfig'

module Celluloid
  module CPUCounter
    case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
    when 'darwin'
      @cores = Integer(`sysctl hw.ncpu`[/\d+/])
    when 'linux'
      @cores = File.read("/proc/cpuinfo").scan(/core id\s+: \d+/).uniq.size
    else
      @cores = nil
    end

    def self.cores; @cores; end
  end
end

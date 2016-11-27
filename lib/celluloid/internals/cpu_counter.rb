module Celluloid
  module Internals
    module CPUCounter
      class << self
        def cores
          @cores ||= count_cores
        end

        private unless $CELLULOID_TEST

        def count_cores
          from_result(from_env || from_sysdev || from_java || from_proc || from_win32ole || from_sysctl) || 1
        end

        def from_env
          result = ENV["NUMBER_OF_PROCESSORS"]
          result if result && !result.empty?
        rescue
        end

        def from_sysdev
          ::IO.read("/sys/devices/system/cpu/present").split("-").last.to_i + 1
        rescue Errno::ENOENT
          begin
            result = Dir["/sys/devices/system/cpu/cpu*"].count { |n| n =~ /cpu\d+/ }
            result unless result.zero?
          rescue
          end
        rescue
        end

        def from_java
          Java::Java.lang.Runtime.getRuntime.availableProcessors if defined? Java::Java
        rescue
        end

        def from_proc
          File.read("/proc/cpuinfo").scan(/^processor\s*:/).size if File.exist?("/proc/cpuinfo")
        rescue
        end

        def from_win32ole
          require "win32ole"
          WIN32OLE.connect("winmgmts://").ExecQuery("select * from Win32_ComputerSystem").NumberOfProcessors
        rescue LoadError
        rescue
        end

        def from_sysctl
          Integer `sysctl -n hw.ncpu 2>/dev/null`
        rescue
        end

        def from_result(result)
          if result
            i = Integer(result.to_s[/\d+/], 10)
            return i if i > 0
          end
        rescue
        end
      end
    end
  end
end

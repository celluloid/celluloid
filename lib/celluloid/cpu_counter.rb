module Celluloid
  module CPUCounter
    class << self
      def cores
        @cores ||= count_cores
      end

      private

      def count_cores
        result = from_env || from_sysdev || from_sysctl
        Integer(result.to_s[/\d+/], 10) if result
      end

      def from_env
        result = ENV['NUMBER_OF_PROCESSORS']
        result if result
      end

      def from_sysdev
        ::IO.read('/sys/devices/system/cpu/present').split('-').last.to_i + 1
      rescue Errno::ENOENT
        result = Dir['/sys/devices/system/cpu/cpu*'].count { |n| n =~ /cpu\d+/ }
        result unless result.zero?
      end

      def from_sysctl
        result = `sysctl -n hw.ncpu`
        result if $?.success?
      rescue Errno::ENOENT
      end
    end
  end
end

module Celluloid
  module SupervisionHelper
    def supervise(klass, *args, &block)
      supervise_with_options(klass, prepare_options(args, :block => block))
    end

    def supervise_as(name, klass, *args, &block)
      supervise_with_options(klass, prepare_options(args, :block => block, :as => name))
    end

    private

    def supervise_with_options(klass, options)
      fail NotImplementedError
    end

    def prepare_options(args, options = {})
      ( ( args.length == 1 and args[0].is_a? Hash ) ? args[0] : { :args => args } ).merge( options )
    end
  end
end

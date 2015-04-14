module Debugging
  # Attempt to safely convert an object to a useful string (without side
  # effects if possible)
  #
  # Feel free to add support for more objects/responses/etc.
  def self.dump(obj)
    case obj
    when ::Symbol
      obj.inspect
    when ::String
      obj
    when ::Regexp
      obj.inspect
    when ::IO
      obj.inspect
    when ::Array
      obj.map { |a| Debugging.dump(a) }.to_s
    when ::Celluloid::Response::Success
      "SuccessResponse(#{dump(obj.value)}) (#{dump(obj.call)})"
    when ::Celluloid::Call
      args = obj.arguments.map { |a| Debugging.dump(a) }
      "Call: #{obj}-> #{obj.method.inspect}(#{args.join(', ')})"
    else
      begin
        obj.__send__(:__class__).to_s
      rescue NoMethodError
        obj.__send__(:class).to_s
      end
    end
  end
end

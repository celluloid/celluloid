module CelluloidSpecs
  def self.included_module
    # Celluloid::IO implements this with with 'Celluloid::IO'
    (defined? INCLUDED_MODULE) ? INCLUDED_MODULE : Celluloid
  end
end

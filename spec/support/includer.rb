module CelluloidSpecs
  def self.included_module
    # Celluloid::IO implements this with with 'Celluloid::IO'
    Celluloid
  end
end

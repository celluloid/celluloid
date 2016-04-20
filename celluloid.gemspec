require_relative "../culture/sync"

Gem::Specification.new do |gem|
  gem.name        = "celluloid"
  gem.version     = Celluloid::VERSION
  gem.summary     = "Actor-based concurrent object framework for Ruby"
  gem.description = "Celluloid enables people to build concurrent programs out of concurrent objects just as easily as they build sequential programs out of sequential objects"
  gem.licenses    = ["MIT"]

  gem.authors     = ["Tony Arcieri", "Donovan Keme"]
  gem.email       = ["tony.arcieri@gmail.com", "code@extremist.digital"]
  gem.homepage    = "https://github.com/celluloid/celluloid"

  gem.required_ruby_version     = ">= 1.9.3"

  gem.files        = Dir[
                      "README.md",
                      "CHANGES.md",
                      "LICENSE.txt",
                      "culture/**/*",
                      "lib/**/*",
                    ]

  Celluloid::Sync::Gemspec[gem]
end

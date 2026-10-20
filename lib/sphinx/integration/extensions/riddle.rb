# frozen_string_literal: true

module Sphinx::Integration::Extensions
  module Riddle
    autoload :Query, 'sphinx/integration/extensions/riddle/query'
    autoload :Client, 'sphinx/integration/extensions/riddle/client'
  end
end

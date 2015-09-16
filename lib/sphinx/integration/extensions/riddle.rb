# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    autoload :Query, 'sphinx/integration/extensions/riddle/query'
    autoload :Configuration, 'sphinx/integration/extensions/riddle/configuration'
    autoload :Client, 'sphinx/integration/extensions/riddle/client'
  end
end
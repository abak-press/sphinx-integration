# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Query
      autoload :Insert, 'sphinx/integration/extensions/riddle/query/insert'
      autoload :Update, 'sphinx/integration/extensions/riddle/query/update'
      autoload :Select, 'sphinx/integration/extensions/riddle/query/select'
    end
  end
end
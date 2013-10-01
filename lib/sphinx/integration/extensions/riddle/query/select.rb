# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Query
      module Select

        def reset_values
          @values = []
          self
        end

      end
    end
  end
end
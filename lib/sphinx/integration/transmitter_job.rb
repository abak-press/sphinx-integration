module Sphinx
  module Integration
    class TransmitterJob
      include Resque::Integration

      ALLOWED_ACTIONS = %w(replace delete).freeze

      queue :sphinx
      unique
      ##
      # Трансмитит или удаляет в зависимости от переданного +action+ массив +ids+ модели +klass+
      class << self
        def execute(class_name, action, ids)
          check_action(action)
          klass = class_name.constantize

          klass.define_indexes
          klass.transmitter.public_send(action, ids)
        end

        def enqueue(class_name, action, ids)
          check_action(action.to_s)
          super
        end

        private

        def check_action(action)
          raise ArgumentError.new("Unknown action '#{action}'") unless ALLOWED_ACTIONS.include?(action)
        end
      end
    end
  end
end

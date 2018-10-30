module Sphinx
  module Integration
    class TransmitterJob
      include Resque::Integration

      queue :sphinx
      unique
      ##
      # Трансмитит или удаляет в зависимости от переданного +action+ массив +ids+ модели +klass+

      def self.execute(klass, action, ids)
        klass.constantize.public_send(action, ids)
      end
    end
  end
end

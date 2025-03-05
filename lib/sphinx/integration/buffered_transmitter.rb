module Sphinx
  module Integration
    class BufferedTransmitter < SimpleDelegator
      DEFAULT_SIZE = 100
      attr_reader :buffer_size
      alias transmitter __getobj__

      # Initializer
      #
      # transmitter - Sphinx::Integration::Transmitter
      # options     - Hash
      #             :asynchronous - boolean выполнение буферизированного действия в фоне
      #             :buffer_size  - Integer размер буфера (default: 500)
      #
      # Returns instance
      def initialize(transmitter, options = {})
        super(transmitter)

        options = {
          asynchronous: false,
          buffer_size: DEFAULT_SIZE
        }.merge!(options)

        @asynchronous = options[:asynchronous]
        @buffer_size = @batch_size = options[:buffer_size]

        @buffer = {
          replace: [],
          delete: []
        }
      end

      # Public: Немедленное выполнение буферизированных действий и очистка буфера
      #
      # Returns boolean
      def process_immediate
        temp_buffer_size = 0

        @buffer.each_key do |action|
          temp_buffer_size, @buffer_size = @buffer_size, temp_buffer_size
          public_send(action, [])
          temp_buffer_size, @buffer_size = @buffer_size, temp_buffer_size
        end
      end

      # Обновляет записи в сфинксе
      #
      # records - Array of Integer | Array of AR instances
      #
      # Returns boolean
      def replace(records)
        @buffer[:replace] += Array(records)
        try_process_records(:replace)
      end

      # Удаляет записи из сфинкса
      #
      # records - Array of Integer
      #
      # Returns boolean
      def delete(records)
        @buffer[:delete] += Array(records)
        try_process_records(:delete)
      end

      private

      def try_process_records(action)
        true
      end
    end
  end
end

# coding: utf-8
module SphinxIntegration::Extensions::Search
  extend ActiveSupport::Concern

  included do
    alias_method_chain :populate, :logging
  end

  def populate_with_logging
    return if @populated
    @populated = true
    retries    = hard_retries

    begin
      retry_on_stale_index do
        begin
          log "#{query}, #{options.dup.tap{|o| o[:classes] = o[:classes].map(&:name) if o[:classes] }.inspect}" do
            @results = client.query query, indexes, comment
          end
          total = @results[:total_found].to_i
          log "Found #{total} result#{'s' unless total == 1}"

          log "Sphinx Daemon returned warning: #{warning}" if warning?

          if error?
            log "Sphinx Daemon returned error: #{error}"
            raise SphinxError.new(error, @results) unless options[:ignore_errors]
          end
        rescue Errno::ECONNREFUSED => err
          raise ThinkingSphinx::ConnectionError,
            'Connection to Sphinx Daemon (searchd) failed.'
        end

        compose_results
      end
    rescue => e
      log 'Caught Sphinx exception: %s (%s %s left)' % [
        e.message, retries, (retries == 1 ? 'try' : 'tries')
      ]
      retries -= 1
      if retries >= 0
        retry
      else
        raise e
      end
    end
  end

end
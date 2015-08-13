# coding: utf-8
require 'mysql2'

class Sphinx::Integration::Mysql::Connection
  def initialize(options)
    options[:flags] ||= Mysql2::Client::MULTI_STATEMENTS
    @client_options = options
  end

  def close
    client.close
  rescue
    # silence close
  end

  def execute(statement)
    query(statement).first
  end

  def query_all(*statements)
    query(*statements)
  end

  private

  def client
    @client ||= ::Mysql2::Client.new(@client_options)
  rescue Mysql2::Error => error
    raise ::Sphinx::Integration::QueryExecutionError.new(error)
  end

  def close_and_clear
    close
    @client = nil
  end

  def query(*statements)
    results_for(*statements)
  rescue => error
    human_statements = statements.join('; ')
    message = "#{error.message} - #{human_statements}"
    wrapper = ::Sphinx::Integration::QueryExecutionError.new message
    wrapper.statement = human_statements
    raise wrapper
  ensure
    close_and_clear
  end

  def results_for(*statements)
    results  = [client.query(statements.join('; '))]
    results << client.store_result while client.next_result
    results
  end
end

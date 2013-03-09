# coding: utf-8
require 'mysql2'

class SphinxIntegration::Mysql::Connection
  attr_reader :client

  def initialize(address, port, options)
    @client = Mysql2::Client.new({
      :host  => address,
      :port  => port,
      :flags => Mysql2::Client::MULTI_STATEMENTS
    }.merge(options))
  end

  def close
    client.close
  end

  def execute(statement)
    client.query statement
  rescue
    puts "Error with statement: #{statement}"
    raise
  end

  def query(statement)
    client.query statement
  end

  def query_all(*statements)
    results  = [client.query(statements.join('; '))]
    results << client.store_result while client.next_result
    results
  end
end
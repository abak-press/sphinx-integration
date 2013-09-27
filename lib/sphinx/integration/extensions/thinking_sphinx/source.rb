# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Source
  autoload :SQL, 'sphinx/integration/extensions/thinking_sphinx/source/sql'
  extend ActiveSupport::Concern

  included do
    alias_method_chain :set_source_database_settings, :slave
    include Sphinx::Integration::Extensions::ThinkingSphinx::Source::SQL
  end

  def set_source_database_settings_with_slave(source)
    slave_db_key = @index.local_options[:use_slave_db]
    config = nil

    if slave_db_key
      if slave_db_key.is_a?(String)
        slave_db_key = "#{Rails.env}_#{slave_db_key}"
      else
        slave_db_key = db_config.detect{ |k, _| k =~ /^#{Rails.env}_slave/ }.try(:first)
      end

      if slave_db_key && db_config.key?(slave_db_key)
        config = db_config[slave_db_key].with_indifferent_access
      end
    end

    config ||= @database_configuration

    source.sql_host = config.fetch(:host, 'localhost')
    source.sql_user = config[:username] || config[:user] || ENV['USER']
    source.sql_pass = config[:password].to_s.gsub('#', '\#')
    source.sql_db   = config[:database]
    source.sql_port = config[:port]
    source.sql_sock = config[:socket]

    # MySQL SSL support
    source.mysql_ssl_ca   = config[:sslca]   if config[:sslca]
    source.mysql_ssl_cert = config[:sslcert] if config[:sslcert]
    source.mysql_ssl_key  = config[:sslkey]  if config[:sslkey]
  end

  def db_config
    @db_config ||= YAML.load(IO.read("#{Rails.root}/config/database.yml")).with_indifferent_access
  end

end
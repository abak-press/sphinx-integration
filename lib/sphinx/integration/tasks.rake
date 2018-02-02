%i(start stop running_start index reindex rebuild configure).each do |task|
  Rake::Task["thinking_sphinx:#{task}"].clear_actions
end

namespace :sphinx do
  desc 'Start Sphinx'
  task :start, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).start
  end

  desc 'Stop Sphinx'
  task :stop, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).stop
  end

  desc 'Suspend Sphinx'
  task :suspend, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).suspend
  end

  desc 'Resume Sphinx'
  task :resume, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).resume
  end

  desc 'Restart Sphinx'
  task :restart, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).restart
  end

  desc "Index Sphinx. Task args: host (default: ''), rotate (default: true), *indexes (optional)"
  task :index, %i(host rotate) => :environment do |_, args|
    Rails.application.eager_load!

    rotate = %w(true yes y 1).include?(args[:rotate].presence || 'true')

    Sphinx::Integration::Helper.new(
      host: args[:host],
      rotate: rotate,
      indexes: args.extras,
      logger: ::Sphinx::Integration::Container["logger.index_log"]
    ).index
  end

  desc 'Rebuild Sphinx'
  task :rebuild => ['sphinx:set_indexing_mode', :environment] do
    Rails.application.eager_load!

    Sphinx::Integration::Helper.new(
      logger: Sphinx::Integration::Container["logger.index_log"]
    ).rebuild
  end

  desc 'Generate configuration files'
  task :conf => ['sphinx:set_indexing_mode', :environment] do
    Rails.application.eager_load!

    Sphinx::Integration::Helper.new.configure
  end

  task :set_indexing_mode do
    next if Rails.env.test?

    require 'sphinx/integration/extensions/thinking_sphinx/indexing_mode'
    ThinkingSphinx.indexing_mode = true
  end

  desc 'Copy configuration files'
  task :copy_conf, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: ::Sphinx::Integration::Container["logger.index_log"]
    ).copy_config
  end

  desc 'Clean Sphinx files (indexes and binlogs)'
  task :clean, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: ::Sphinx::Integration::Container["logger.index_log"]
    ).clean
  end

  desc 'Reload config or rotate indexes'
  task :reload, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(
      host: args[:host],
      logger: ::Sphinx::Integration::Container["logger.index_log"]
    ).reload
  end
end

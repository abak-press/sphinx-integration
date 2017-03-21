# coding: utf-8
[:start, :stop, :running_start, :index, :reindex, :rebuild, :configure].each do |task|
  Rake::Task["thinking_sphinx:#{task}"].clear_actions
end

namespace :sphinx do
  desc 'Start Sphinx'
  task :start, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).start
  end

  desc 'Stop Sphinx'
  task :stop, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).stop
  end

  desc 'Suspend Sphinx'
  task :suspend, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).suspend
  end

  desc 'Resume Sphinx'
  task :resume, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).resume
  end

  desc 'Restart Sphinx'
  task :restart, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).restart
  end

  desc <<-TEXT
    Index Sphinx

    host – A domain of remote Sphinx, used all hosts when is empty (default: '')
    rotate – Should rotate indexes when indexing is complete (default: true)
  TEXT
  task :index, [:host, :rotate] => :environment do |_, args|
    Rails.application.eager_load!

    rotate = %w(true yes y 1).include?(args[:rotate].presence || 'true')

    Sphinx::Integration::Helper.
      new(host: args[:host], rotate: rotate, logger: Sphinx::Integration::Container["logger.index_log"]).
      index
  end

  desc 'Rebuild Sphinx'
  task :rebuild => ['sphinx:set_indexing_mode', :environment] do
    Rails.application.eager_load!

    Sphinx::Integration::Helper.
      new(logger: Sphinx::Integration::Container["logger.index_log"]).
      rebuild
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
    Sphinx::Integration::Helper.new(args.to_hash).copy_config
  end

  desc 'Remove indexes files'
  task :rm_indexes, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).remove_indexes
  end

  desc 'Remove binlog files'
  task :rm_binlog, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).remove_binlog
  end

  desc 'Reload config or rotate indexes'
  task :reload, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args.to_hash).reload
  end
end

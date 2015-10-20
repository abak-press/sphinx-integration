namespace :thinking_sphinx do
  def wrap_task(*args, &block)
    name, params, deps = Rake.application.resolve_args(args.dup)
    task = Rake::Task["thinking_sphinx:#{name}"]
    task.clear_actions
    task.enhance(&block)
  end

  wrap_task :stop do
    Sphinx::Integration::Helper.new.stop
  end

  wrap_task :start do
    Sphinx::Integration::Helper.new.start
  end

  wrap_task :running_start do
    Sphinx::Integration::Helper.new.restart
  end

  wrap_task :index do
    Sphinx::Integration::Helper.new.index
  end

  wrap_task :reindex do
    Sphinx::Integration::Helper.new.reindex
  end

  wrap_task :rebuild do
    Sphinx::Integration::Helper.new.rebuild
  end

  wrap_task :configure do
    Sphinx::Integration::Helper.new.configure
  end
end

namespace :sphinx do
  desc 'Start Sphinx'
  task :start, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).start
  end

  desc 'Stop Sphinx'
  task :stop, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).stop
  end

  desc 'Restart Sphinx'
  task :restart, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).restart
  end

  desc 'Index Sphinx'
  task :index, [:host, :offline] => :environment do |_, args|
    Rails.application.eager_load!

    is_offline = (offline = args.delete(:offline)).present? && %w(true yes y da offline).include?(offline)
    Sphinx::Integration::Helper.new(args).index(!is_offline)
  end

  desc 'Rebuild Sphinx'
  task :rebuild => :environment do
    Rails.application.eager_load!
    Sphinx::Integration::Helper.new.rebuild
  end

  desc 'Generate configuration files'
  task :conf => ['sphinx:set_indexing_mode', :environment] do
    Rails.application.eager_load!
    Sphinx::Integration::Helper.new.configure
  end

  task :set_indexing_mode do
    require 'sphinx/integration/extensions/thinking_sphinx/indexing_mode'
    ThinkingSphinx.indexing_mode = true
  end

  desc 'Copy configuration files'
  task :copy_conf, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).copy_config
  end

  desc 'Remove indexes files'
  task :rm_indexes, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).remove_indexes
  end

  desc 'Remove binlog files'
  task :rm_binlog, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).remove_binlog
  end

  desc 'Reload config or rotate indexes'
  task :reload, [:host] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args).reload
  end
end

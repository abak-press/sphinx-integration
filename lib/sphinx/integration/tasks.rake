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
  task :start, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).start
  end

  desc 'Stop Sphinx'
  task :stop, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).stop
  end

  desc 'Restart Sphinx'
  task :restart, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).restart
  end

  desc 'Index Sphinx'
  task :index, [:node, :offline] => :environment do |_, args|
    Rails.application.eager_load!

    is_offline = args[:offline].present? && %w(true yes y da offline).include?(args[:offline])
    Sphinx::Integration::Helper.new(args[:node]).index(!is_offline)
  end

  desc 'Rebuild Sphinx'
  task :rebuild, [:node] => :environment do |_, args|
    Rails.application.eager_load!
    Sphinx::Integration::Helper.new(args[:node]).rebuild
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
  task :copy_conf, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).copy_config
  end

  desc 'Remove indexes files'
  task :rm_indexes, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).remove_indexes
  end

  desc 'Remove binlog files'
  task :rm_binlog, [:node] => :environment do |_, args|
    Sphinx::Integration::Helper.new(args[:node]).remove_binlog
  end

end

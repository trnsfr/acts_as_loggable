class ActivityMigrationGenerator < Rails::Generator::NamedBase
  attr_reader :activity_table_name
  def initialize(runtime_args, runtime_options = {})
    @activity_table_name = (runtime_args.length < 2 ? 'activities' : runtime_args[1]).tableize
    runtime_args << 'add_activity_table' if runtime_args.empty?
    super
  end

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
end

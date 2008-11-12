class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= activity_table_name %>", :force => true do |t|
      t.string :note, :path, :logged_by, :loggable_type
      t.integer :loggable_id, :account_id
      t.datetime :created_at
    end
  end

  def self.down
    drop_table "<%= activity_table_name %>"
  end
end

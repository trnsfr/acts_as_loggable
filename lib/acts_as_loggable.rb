module Trnsfr
  module Acts #:nodoc:
    module Loggable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
        class << base
          attr_accessor :activity_account_id
          attr_accessor :activity_field
          attr_accessor :activity_link_path
          attr_accessor :activity_ignore_columns
          attr_accessor :activity_messages
          attr_accessor :activity_skip_methods
        end
      end

      module ClassMethods

        def acts_as_loggable(options={})
          cattr_accessor :activity_color
          
          default_messages = {
            :created => ":field was :action",
            :deleted => ":field was :action",
            :updated => ":field: :updated changed"
          }

          ((options[:ignore_columns] ||= []) << ["created_at", "updated_at"])
          options[:path] ||= "/#{self.to_s.downcase.pluralize}/:id"
          options[:skip] ||= []
          self.activity_field          = options[:field] || "to_s"
          self.activity_link_path      = options[:path]
          self.activity_ignore_columns = options[:ignore_columns].flatten
          self.activity_messages       = (options[:messages] ||= {}).reverse_merge(default_messages)
          self.activity_color          = options[:color]
          self.activity_account_id     = options[:account_id] || :account_id
          self.activity_skip_methods   = options[:skip]
          
          after_create  { |record| Activity.log(:created, record) }
          after_update  { |record| Activity.log(:updated, record) }
          after_destroy { |record| Activity.log(:deleted, record) }
          
        end

      end
      
    end
  end  
end


class Activity < ActiveRecord::Base
  belongs_to :loggable, :polymorphic => true
  cattr_accessor :current_user
  cattr_accessor :current_account
  
  class << self
    
    def activities(ids, options={})
      ids = [ids].flatten.join(",")
      options = {:select => "DISTINCT *", :conditions => "account_id IN(#{ids})", :group => "created_at", :order => "created_at DESC", :limit => 50}.merge(options)
      activities = find(:all, options)
    end
    
    
    def log(action, record)
      @action, @record = action, record
    
      # Determine what fields have been changed
      @changed = @record.changed - @record.class.activity_ignore_columns

      # If a user passes :skip option, do not run
      return if @record.class.activity_skip_methods.include?(@action)
      return unless @changed.any? || @action == :deleted
    
      @path = @record.class.activity_link_path
      @note = @record.class.activity_messages[@action] rescue ":to_s was :action"
    
      # If user sets account_id in the model, it will override a global account_id
      account_id = current_account.blank? ? @record.send(@record.class.activity_account_id) : [current_account]
      
      # Make sure account_id is an array of ids
      account_id = [account_id].flatten
      
      # Parse "path" and "note" strings
      @path, @note = parse_path_and_note

      # Don't store path if item was deleted
      @path = nil if @action == :deleted
    
      # Create a activity for each account
      account_id.each { |id| create_record(id) }
    rescue
    end
  
  
    def create_record(id)
      # call id if it's an instance of the class
      id = id.id unless id.is_a?(Integer) || id.is_a?(String)
      
      create(:logged_by => user,
             :account_id => id,
             :note => @note,
             :path => @path,
             :loggable_type => @record.class.to_s,
             :loggable_id => @record.id)
    end
  
  
    def parse_path_and_note
      items = [@path, @note]
      items.each_with_index do |string, index|
        string = string.gsub(":action", @action.to_s)
        string = string.gsub(":updated", @changed.to_sentence)
        string = string.gsub(":field", eval("@record.#{@record.class.activity_field}"))
        string = string.gsub(/\{(.*?)\}/){ eval($1.gsub("self", "@record")) }
        string = string.gsub(/\:([a-zA-Z_]+)?/){ $1.nil? ? ":" : @record.send($1) }
        items[index] = string
      end
      return items
    end


    def user
      User.find(current_user).to_s rescue ""
    end
  end

end

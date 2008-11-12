require 'acts_as_loggable'
ActiveRecord::Base.send(:include, Trnsfr::Acts::Loggable)
ActionController::Base.send(:include, LogFilters)


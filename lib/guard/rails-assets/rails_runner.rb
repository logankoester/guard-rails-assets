require 'rake/dsl_definition'
module Guard

  class RailsAssets::RailsRunner
    @@rails_booted = false # Only one rails app is allowed, so make it a class var
    @@rails_env = nil

    def initialize(options={})
      @@rails_env = (options[:rails_env] || 'test').to_s unless @@rails_booted
    end

    def self.apply_hacks
      # TODO: Hack due to Rails 3.1 issue: https://github.com/rails/rails/issues/2663#issuecomment-1990121
      ENV["RAILS_GROUPS"] ||= "assets"
      ENV["RAILS_ENV"]    ||= @@rails_env

      # TODO: Now another hack: Rails replaces Rails.application.assets with Rails.applciation.assets.index
      # (this happens when config.action_controller.perform_caching is true)
      # It caches all the assets, so that the Rakse task can't be reused
      require 'sprockets/environment'
      Sprockets::Environment.class_eval do
        def index; self; end # instead of Index.new(self)
      end
    end

    # Methods to run the asset pipeline
    # See as a reference https://github.com/rails/rails/blob/master/actionpack/lib/sprockets/assets.rake
    def self.boot_rails
      return if @@rails_booted
      puts "Booting Rails for #{@@rails_env} environment."
      apply_hacks
      require 'rake'
      require "#{Dir.pwd}/config/environment.rb"
      app = ::Rails.application

      app.assets.cache = nil # don't touch my FS pls. (can we use `app.config.assets.cache_store = false` instead)?
      app.load_tasks
      @@rails_booted = true
    end


    # Runs the asset pipeline compiler.
    #
    # @return [ Boolean ] Whether the compilation was successful or not
    def compile_assets
      self.class.boot_rails
      return false unless @@rails_booted
      begin
        Rake::Task['assets:clean'].execute
        Rake::Task['assets:precompile'].execute
        true
      rescue => e
        puts "An error occurred compiling assets: #{e}"
        false
      end
    end
  end
end

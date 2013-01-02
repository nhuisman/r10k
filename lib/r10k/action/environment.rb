require 'r10k/action'
require 'r10k/action/module'
require 'r10k/deployment'

require 'middleware'

module R10K::Action::Environment

  class Deploy
    def initialize(app, root)
      @app, @root = app, root
    end

    # @param [Hash] env
    #
    # @option env [true, false] :update_cache
    # @option env [true, false] :recurse
    def call(env)
      @env = env

      puts "Deploying #{@root.full_path}"
      FileUtils.mkdir_p @root.full_path
      @root.sync! :update_cache => @env[:update_cache]

      if @env[:recurse]
        # Build a new middleware chain and run it
        stack = Middleware::Builder.new
        @root.modules.each { |mod| stack.use R10K::Action::Module::Deploy, mod }
        stack.call(@env)
      end

      @app.call(@env)
    end
  end

  class Purge
    # Middleware action to purge stale environments
    def initialize(app, path)
      @app, @path = app, path
    end

    def call(env)
      @env = env

      stale_directories = R10K::Deployment.instance.collection.stale(@path)

      stale_directories.each do |dir|
        puts "Would purge #{dir.inspect}".green
      end

      @app.call(@env)
    end
  end
end

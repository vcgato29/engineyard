require 'uri'
require 'engineyard/error'

module EY
  class Config
    def initialize(content)
      @config = content || {}
      @config["environments"] ||= {}
    end

    def method_missing(meth, *args, &blk)
      key = meth.to_s.downcase
      if @config.key?(key)
        @config[key]
      else
        super
      end
    end

    def respond_to?(meth)
      key = meth.to_s.downcase
      @config.key?(key) || super
    end

    def endpoint
      @endpoint ||= env_var_endpoint || default_endpoint
    end

    def env_var_endpoint
      if endpoint = ENV["CLOUD_URL"]
        assert_valid_endpoint endpoint, "CLOUD_URL"
      end
    end

    def default_endpoint
      URI.parse("https://cloud.engineyard.com/")
    end

    def default_environment
      d = environments.find do |name, env|
        env["default"]
      end
      d && d.first
    end

    def default_branch(environment = default_environment)
      env = environments[environment]
      env && env["branch"]
    end

    private

    def assert_valid_endpoint(endpoint, source)
      endpoint = URI.parse(endpoint) if endpoint.is_a?(String)
      return endpoint if endpoint.absolute?

      raise ConfigurationError.new('endpoint', endpoint.to_s, source, "endpoint must be an absolute URI")
    end

    class ConfigurationError < EY::Error
      def initialize(key, value, source, message=nil)
        super %|"#{key}" from #{source} has invalid value: #{value.inspect}#{": #{message}" if message}|
      end
    end
  end
end

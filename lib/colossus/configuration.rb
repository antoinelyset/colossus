# encoding: utf-8
# Main Colossus module
class Colossus
  # Handles all the configuration
  class Configuration
    attr_accessor :ttl, :seconds_before_ttl_check, :engine,
                  :secret_key, :writer_token

    def initialize
      @ttl = 10
      @seconds_before_ttl_check = 2
      @engine = Colossus::Engine::Memory
      @secret_key = ''
      @writer_token = ''
    end
  end # class Configuration

  def self.configure
    yield(configuration) if block_given?
    configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config
    configuration
  end

  # Help ?
  # rubocop:disable TrivialAccessors
  def self.configuration=(configuration)
    @configuration = configuration
  end
  # rubocop:enable

  def self.config=(configuration)
    self.configuration = configuration
  end

  def self.reset_configuration
    @configuration = Configuration.new
  end
end # Colossus

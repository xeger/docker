require_relative 'docker/version'
require_relative 'docker/error'
require_relative 'docker/asset'
require_relative 'docker/container'
require_relative 'docker/cli'
require_relative 'docker/session'

module Docker
  # Create a new session with default options.
  def self.new
    Session.new
  end
end

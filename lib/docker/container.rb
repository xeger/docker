module Docker
  # Object that represents a Docker container, its information and operations.
  class Container < Asset
    # @return [String] unique SHA256 container hash
    def id
      @json['Id']
    end

    # @return [String] human-readable name of container ()minus initial /)
    def name
      super.sub(/^\//, '')
    end

    # @return [String] SHA256 hash of image the container is derived from
    def image
      @json['Image']
    end

    # @return [String] running, exited, etc
    def status
      @json['State']['Status']
    end

    # @return [Integer] master process PID
    def pid
      @json['State']['Pid']
    end

    # @return [Integer] master process exit code
    def exit_code
      @json['State']['ExitCode']
    end

    def kill
      raise Error, "Disconnected from session" unless @session
      @session.kill(id)
    end

    def rm
      raise Error, "Disconnected from session" unless @session
      @session.rm(id)
    end

    def start
      raise Error, "Disconnected from session" unless @session
      @session.start(id)
    end

    def stop
      raise Error, "Disconnected from session" unless @session
      @session.stop(id)
    end
  end
end

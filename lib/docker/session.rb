require 'backticks'
require 'json'

module Docker
  # A Ruby OOP interface to a docker session. A session is bound to
  # a particular docker host (which is set at initialize time)
  # time) and invokes whichever docker command is resident in $PATH.
  #
  # Run docker commands by calling instance methods of this class and
  # passing positional and kwargs that are equivalent to the CLI options
  # you would pass to the command-line tool.
  #
  # Note that the Ruby command methods usually expose a _subset_ of the options
  # allowed by the docker CLI, and that options are sometimes renamed
  # for clarity. Each command method is extensively documented.
  class Session
    # @return [String] URL of the Docker host associated with this session
    attr_reader :host

    # @return [#command]
    attr_reader :shell

    # Hint that we are able to parse ps output
    PS_HEADER = /ID\s+IMAGE\s+COMMAND\s+CREATED\s+STATUS\s+PORTS\s+NAMES$/

    def initialize(shell=Backticks::Runner.new(cli: Docker::CLI::Getopt), host:ENV['DOCKER_HOST'])
      @host = host
      @shell = shell
    end

    # Get detailed information about a container(s).
    #
    # @return [Container,Array] one container if one was asked about; a list of containers otherwise
    # @param [Array,String] container ID/name or list of IDs/names
    def inspect(container_s)
      containers = container_s
      containers = [containers] unless container_s.is_a?(Array)
      return [] if containers.empty?
      out = run!('inspect', containers)
      result = JSON.parse(out).map { |c| Container.new(c, session:self)}
      if container_s.is_a?(Array)
        result
      else
        result.first
      end
    end

    # Kill a running container.
    #
    # @param [String] container id or name of container
    # @param [String] signal Unix signal to send: KILL, TERM, QUIT, HUP, etc
    def kill(container, signal:nil)
      run!('kill', {signal:signal}, container)
    end

    # List containers. This actually does a `ps` followed by a very large
    # `inspect`, so it's expensive but super detailed.
    #
    # @param
    # @return [Array] list of Docker::Container objects
    def ps(all:false, before:nil, latest:false, since:nil)
      out = run!('ps', all:all,before:before,latest:latest,since:since)
      lines = out.split(/[\n\r]+/)
      header = lines.shift
      ids = lines.map { |line| line.split(/\s+/).first }
      inspect(ids)
    end

    # Run a command in a new container.
    #
    # @example open a busybox shell
    #   session.run('busybox', '/bin/sh', tty:true, interactive:true)
    #
    # @param [String] image id or name of base image to use for container
    # @param [Array] command_and_args optional command to run in container
    # @param [Integer] cpu_period scheduler period (μs)
    # @param [Integer] cpu_quota maximum runtime (μs) during one scheduler period
    # @param [Boolean] detach run container in background and return immediately
    # @param [Array,Hash] env environment variables; map of {K:V} pairs or list of ["K=V"] assignments
    # @param [String] env_file name of file to read environment variables from
    # @param [Array] expose list of Integer/String ports or port-ranges to expose to other containers e.g. 80, "1024-2048"
    # @param [String] hostname Unix hostname inside container
    # @param [Boolean] interactive allocate an STDIN for the container
    # @param [Array] link list of container ids or names to link to the container
    # @param [String] memory limit on memory consumption e.g. "640k", "32m" or "4g"
    # @param [String] name name of container; leave blank to let Docker generate one
    # @param [Array] publish list of Integer/String ports or port-ranges to publish to the host; use "X:Y" to map container's X to host's Y
    # @param [Boolean] publish_all automatically publish all of container's ports to the host
    # @param [Boolean] restart automatically restart container when it fails
    # @param [Boolean] rm clean up container once it exits
    # @param [Boolean] tty allocate a pseudo-TTY for the container's STDOUT
    # @param [String] user name or uid of Unix user to run container as
    # @param [Array] volume list of volumes to mount inside container; use "X:Y" to map host's X to container's Y
    # @param [String] volumes_from id or name of container to import all volumes from
    def run(image, *command_and_args,
            add_host:[],
            attach:[],
            cpu_period:nil,
            cpu_quota:nil,
            detach:false,
            env:{},
            env_file:nil,
            expose:[],
            hostname:nil,
            interactive:false,
            link:[],
            memory:nil,
            name:nil,
            publish:[],
            publish_all:false,
            restart:false,
            rm:false,
            tty:false,
            user:nil,
            volume:[],
            volumes_from:nil)

      cmd = []

      # if env was provided as a hash, turn it into an array
      env = env.map { |k, v| "#{k}=#{v}" } if env.is_a?(Hash)

      # our keyword args are formatted properly for run! to handle them; echo
      # them into the command line verbatim.
      # TODO find a way to DRY out this repetitive mess...
      cmd << {add_host:add_host, attach:attach, cpu_period:cpu_period,
              cpu_quota:cpu_quota, detach:detach, env_file:env_file, env:env,
              expose:expose, hostname:hostname, interactive:interactive,
              link:link, memory:memory, name:name, publish:publish,
              publish_all:publish_all, restart:restart, rm:rm, tty:tty,
              user:user, volume:volume, volumes_from:volumes_from
      }.reject { |k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }


      # after the options come the image and command
      cmd << image
      cmd.concat(command_and_args)

      # return the output of `docker run` minus extra whitespace
      run!('run', *cmd).strip
    end

    # Remove a container.
    #
    # @param [String] container id or name of container
    # @param [Boolean] force remove the container even if it's in use
    # @param [Boolean] volumes remove associated data volumes
    def rm(container, force:false, volumes:false)
      run!('rm', {force:force,volumes:volumes},container).strip
    end

    # Stop a running container.
    #
    # @param [String] container id or name of container
    # @param [Integer] time seconds to wait for stop before killing it
    def stop(container, time:nil)
      run!('stop', {time:time}, container).strip
    end

    # Start a stopped container.
    #
    # @param [String] container id or name of container
    # @param [Boolean] attach attach STDOUT/STDERR and forward signals
    # @param [Boolean] interactive attach container's STDIN
    def start(container, attach:false, interactive:false)
      run!('start', {attach:attach,interactive:interactive}, container).strip
    end

    # Provide version information about the Docker client and server.
    #
    # @return [Hash] dictionary of strings describing version/build info
    # @raise [Error] if command fails
    def version
      result = run!('version')

      lines = result.split(/[\r\n]+/)

      info = {}
      prefix = ''

      lines.each do |line|
        if line =~ /^Client/
          prefix = 'Client '
        elsif line =~ /^Server/
          prefix = 'Server '
        else
          pair = line.split(':',2).map { |e| e.strip }
          info["#{prefix}#{pair[0]}"] = pair[1]
        end
      end

      info
    end

    # Run a docker command without validating that the CLI parameters
    # make sense. Prepend implicit options if suitable.
    #
    # @param [Array] args command-line arguments in the format accepted by
    #   Backticks::Runner#command
    # @return [String] output of the command
    # @raise [RuntimeError] if command fails
    def run!(*args)
      # STDERR.puts "+ " + (['docker'] + args).inspect
      cmd = @shell.run('docker', *args).join
      status, out, err = cmd.status, cmd.captured_output, cmd.captured_error
      status.success? || raise(Error.new(args.first, status, err))
      out
    end
  end
end

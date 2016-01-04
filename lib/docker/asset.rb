module Docker
  # Base class for containers, images and other Docker assets.
  class Asset
    def initialize(json, session:nil)
      json = JSON.load(json) if json.is_a?(String)
      @json = json
      @session = session
    end

    def inspect
      %Q{#<#{self.class.name}:#{self.name}>}
    end

    # @return [String] human-readable name of container, image or volume
    def name
      @json['Name']
    end

    def to_h
      @json
    end

    def to_s
      self.inspect
    end
  end
end

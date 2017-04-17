module Docker
  # Docker command-line parameter generator.
  # This is a modified version of Backticks::CLI::Getopt, made specially for converting ruby objects
  # into Docker CLI opts.
  module CLI
    # Translate a series Ruby positional and keyword arguments into Docker command-
    # parameters consisting of words and options.
    #
    # Each positional argument can be a Hash, an Array, or another object.
    # They are handled as follows:
    #  - Hash is translated to a sequence of options; see #options
    #  - Array is appended to the command line as a sequence of words
    #  - other objects are turned into a string with #to_s and appended to the command line as a
    #    single word
    #
    # @return [Array] list of String words and options
    #
    # @example recursively find all text files
    #   parameters('docker', 'run', 'hello_world')
    #
    # @example run & remove docker hello world
    #   parameters('docker', 'run', rm: true, 'hello_world')
    module Getopt
      def self.parameters(*sugar)
        sugar.each_with_object [] do |item, argv|
          argv.concat extract_parameter(item)
        end
      end

      def self.extract_parameter(item)
        return item.map(&:to_s) if item.is_a? Array
        return options(item) if item.is_a? Hash
        [item.to_s]
      end

      def self.options(kwargs = {})
        # Transform opts into golang flags-style command line parameters;
        # append them to the command.
        kwargs.map { |kw, arg| convert_option kw, arg }.compact.flatten
      end

      def self.convert_option(option_name, option_value)
        flag = (option_name.length == 1) ? "-#{option_name}" : "--#{option_name}"
        return [flag] if option_value == true
        return process_list_option flag, option_value if option_value.is_a? Array
        return process_non_null_option flag, option_value if option_value
      end

      def self.process_list_option(flag, option_value)
        option_value.map do |value_item|
          process_non_null_option flag, value_item if value_item
        end.compact.flatten
      end

      def self.process_non_null_option(flag, option_value)
        is_long_flag = flag[0..1] == '--'
        return "#{flag}=#{option_value}" if is_long_flag
        [flag, option_value.to_s]
      end
    end
  end
end

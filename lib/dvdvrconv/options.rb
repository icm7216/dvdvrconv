module Dvdvrconv
  module Options
    def self.parse(argv)
      options = {}

      parser = OptionParser.new do |o|
        o.on_head("-v", "--version", "Show version") do |v|
          options[:version] = v
          o.version = Dvdvrconv::VERSION
          puts o.version
          exit
        end

        o.on("-i", "--info", "Show file information") do |v|
          options[:info] = v
        end

        o.on("-c", "--config=FILE", String, "Use YAML format FILE.") do |file|
          options[:config_file] = file
        end

        o.on("-e", "--exec", "Execute the vob file to mp4 conversion.") do |v|
          options[:exec] = v
        end
      end

      begin
        remained = parser.parse!(argv)
      rescue OptionParser::InvalidArgument => e
        abort e.message
      rescue OptionParser::MissingArgument => e
        case e.args
        when ["-c"], ["--config"]
          # load_config(Dvdvrconv::DEFAULT_CONFIG_FILE)
          puts "The config file has not been specified.\nUse the default configuration file. (=> #{Dvdvrconv::DEFAULT_CONFIG_FILE})"
          options[:config_file] = Dvdvrconv::DEFAULT_CONFIG_FILE
        end
      end

      { opt: options }
    end
  end
end

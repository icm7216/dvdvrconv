# frozen_string_literal: true

module Dvdvrconv
  class Command
    def self.run(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv
      @options = {}

      config_file = Dvdvrconv::DEFAULT_CONFIG_FILE
      if File.exist?(config_file)
        puts "Read the default config file. => #{config_file}"
        load_config(config_file)
      end
    end

    # For now, this test code returns dummy dvd-vr information.
    def execute
      options = Dvdvrconv::Options.parse(@argv)
      dvd = Dvdvrconv::Dvdvr.new

      # Set the path specified in the yaml file.
      if @options[:vr_mangr_ifo]
        dvd.vrdisc.opts_ifo = @options[:vr_mangr_ifo]
      else
        dvd.vrdisc.opts_ifo = dvd.vrdisc.default_opts_ifo
      end

      if @options[:vr_movie_vro]
        dvd.vrdisc.opts_vro = @options[:vr_movie_vro]
      else
        dvd.vrdisc.opts_vro = dvd.vrdisc.default_opts_vro
      end

      if @options[:dvd_vr_cmd]
        dvd.vrdisc.cmd = @options[:dvd_vr_cmd]
      else
        dvd.vrdisc.cmd = dvd.vrdisc.default_cmd
      end

      if options[:opt][:config_file]
        puts "Use config file\n  => #{options[:opt][:config_file]}"
        opt_config_file = options[:opt][:config_file]
        load_config(opt_config_file) if File.exist?(opt_config_file)
        dvd.vrdisc.opts_ifo = @options[:vr_mangr_ifo] if @options[:vr_mangr_ifo]
        dvd.vrdisc.opts_vro = @options[:vr_movie_vro] if @options[:vr_movie_vro]
        dvd.vrdisc.cmd = @options[:dvd_vr_cmd] if @options[:dvd_vr_cmd]
      end

      if @options[:concat_mode].nil?
        dvd.vrdisc.concat_mode = Dvdvrconv::DEFAULT_CONCAT_MODE
      else
        dvd.vrdisc.concat_mode = @options[:concat_mode]
      end

      if @options[:hardware_encode].nil?
        dvd.vrdisc.hardware_encode = DEFAULT_HARDWARE_ENCODE
      else
        dvd.vrdisc.hardware_encode = @options[:hardware_encode]
      end

      if @options[:global_quality].nil?
        dvd.vrdisc.global_quality = Dvdvrconv::DEFAULT_GLOBAL_QUALITY
      else
        dvd.vrdisc.global_quality = @options[:global_quality]
      end

      # View the path of each files
      puts '== Use these paths =='
      puts "  => VR_MANGR.IFO:        #{dvd.vrdisc.opts_ifo}"
      puts "  => VR_MOVIE.VRO:        #{dvd.vrdisc.opts_vro}"
      puts "  => dvd-vr.exe:          #{dvd.vrdisc.cmd}"
      puts '== Customize settings =='
      puts "  => use_customize_title: #{@options[:use_customize_title]}"
      puts "  => base_dst_name:       #{@options[:base_dst_name]}"
      puts "  => number_list:         #{@options[:number_list]}"
      puts "  => concat_mode:         #{@options[:concat_mode]}"
      puts "  => hardware_encode:     #{@options[:hardware_encode]}"
      puts "  => global_quality:      #{@options[:global_quality]}"

      dvd.read_info

      dvd.view_info if options[:opt][:info] || options[:opt].empty?
      exit unless options[:opt][:exec]

      # Extract vob files
      dvd.adjust_title
      dvd.vro2vob

      # Change the file name to the title name
      dvd.change_to_title_name
      dvd.rename_vob

      # Concatenate Split titles
      if dvd.vrdisc.concat_mode == true
        puts '== Concatenate Split titles =='
        concat_list = dvd.make_concat_list
        dvd.concat_titles(concat_list)
      end

      # customize title of vob files
      case @options[:use_customize_title]
      when 1
        puts 'Specify individual file names.'

        if @options[:base_dst_name].class == Array
          base_dst_name = @options[:base_dst_name]
        else
          puts "ERROR: base_dst_name should be an Array. \n  ( => #{@options[:base_dst_name]})"
          exit
        end

        number_list = []
      when 2
        puts 'Add sequence number to the file name.'

        if @options[:base_dst_name].class == String
          base_dst_name = @options[:base_dst_name]
        else
          puts "ERROR: base_dst_name should be String. \n  ( => #{@options[:base_dst_name]})"
          exit
        end

        number_list = []
      when 3
        puts 'Specify sequence numbers individually.'

        if @options[:base_dst_name].class == String
          base_dst_name = @options[:base_dst_name]
        else
          puts "ERROR: base_dst_name should be String. \n  ( => #{@options[:base_dst_name]})"
          exit
        end

        if @options[:number_list].class == Array
          number_list = @options[:number_list]
        else
          puts 'ERROR: number_list should be an Array.'
          exit
        end

      else
        puts 'No customize file names'
        base_dst_name = dvd.vrdisc.title.uniq.map { |file| file[0].gsub(/\s/, '_') }
        number_list = []
      end

      dvd.customize_title(base_dst_name, number_list)
      dvd.rename_vob

      # convert vob to mp4
      dvd.vob2mp4
    end

    # load yaml file and store in @options.
    def load_config(file)
      config = YAML.safe_load(File.read(file)) || {}

      %w[vr_mangr_ifo vr_movie_vro dvd_vr_cmd].each do |key|
        @options[key.to_sym] = nil

        unless config.key?(key)
          puts "[ #{key} ] does not exist in #{file} file."
        else
          if File.exist?(config[key])
            @options[key.to_sym] = config[key]
          else
            puts "File read error. No such file: #{config[key]}"
          end
        end

      end

      @options[:use_customize_title] = config['use_customize_title'] || 'no'
      @options[:base_dst_name] = config['base_dst_name'] || []
      @options[:number_list] = config['number_list'] || []

      if config['concat_mode'].nil?
        @options[:concat_mode] = Dvdvrconv::DEFAULT_CONCAT_MODE
      else
        @options[:concat_mode] = config['concat_mode']
      end

      if config['hardware_encode'].nil?
        @options[:hardware_encode] = 'normal'
      else
        @options[:hardware_encode] = config['hardware_encode']
      end

      if config['global_quality'].nil?
        @options[:global_quality] = Dvdvrconv::DEFAULT_GLOBAL_QUALITY
      else
        @options[:global_quality] = config['global_quality']
      end
    end

    def dvdpath
      {
        :vr_mangr_ifo => @options[:vr_mangr_ifo],
        :vr_movie_vro => @options[:vr_movie_vro],
        :dvd_vr_cmd => @options[:dvd_vr_cmd]
      }
    end
  end
end

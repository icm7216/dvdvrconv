# frozen_string_literal: true

module Dvdvrconv

  # DVD-VR disc status
  Vrdisc = Struct.new(
    :header,            # @param [String]
    :num,               # @param [Array<String>]
    :title,             # @param [Array<String>]
    :date,              # @param [Array<String>]
    :size,              # @param [Array<String>]
    :opts_ifo,          # @param [String]
    :opts_vro,          # @param [String]
    :cmd,               # @param [String]
    :output_title,      # @param [Array<String>]
    :duplicate_name,    # @param [Array<String>]
    :vob_titles,        # @param [Array<String>]
    :default_opts_ifo,  # @param [String]
    :default_opts_vro,  # @param [String]
    :default_cmd,       # @param [String]
    :concat_mode,       # @param [Boolean]
    :hardware_encode    # @param [String]
  )

  BASE_NAME = 'DVD'
  DEFAULT_CONFIG_FILE = 'default_dvdvrconv.yml'
  DEFAULT_CONCAT_MODE = true
  DEFAULT_HARDWARE_ENCODE = 'normal'

  # Default DVD drive is "d".
  # If you want to use a different drive, you need to set up a "default_dvdvrconv.yml" file.
  WIN_DRV_IFO = '/cygdrive/D/DVD_RTAV/VR_MANGR.IFO'
  WIN_DRV_VRO = '/cygdrive/D/DVD_RTAV/VR_MOVIE.VRO'
  WIN_DRV_CMD = File.expand_path('../../win/dvd-vr.exe', __dir__)
  DRV_IFO = '/mnt/d/DVD_RTAV/VR_MANGR.IFO'
  DRV_VRO = '/mnt/d/DVD_RTAV/VR_MOVIE.VRO'
  DRV_CMD = 'dvd-vr'

  class Dvdvr
    attr_accessor :vrdisc

    def initialize
      @vrdisc = Vrdisc.new(nil)

      if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin/
        @vrdisc.opts_ifo = Dvdvrconv::WIN_DRV_IFO
        @vrdisc.opts_vro = Dvdvrconv::WIN_DRV_VRO
        @vrdisc.cmd = Dvdvrconv::WIN_DRV_CMD
      else
        @vrdisc.opts_ifo = Dvdvrconv::DRV_IFO
        @vrdisc.opts_vro = Dvdvrconv::DRV_VRO
        @vrdisc.cmd = Dvdvrconv::DRV_CMD
      end

      @vrdisc.default_opts_ifo = @vrdisc.opts_ifo
      @vrdisc.default_opts_vro = @vrdisc.opts_vro
      @vrdisc.default_cmd = @vrdisc.cmd
      @vrdisc.concat_mode = Dvdvrconv::DEFAULT_CONCAT_MODE
      @vrdisc.hardware_encode = Dvdvrconv::DEFAULT_HARDWARE_ENCODE
    end

    # Read VRO file from dvd-ram disc in dvd-vr format, and output vob files.
    def str_dvdvr_cmd
      %(#{@vrdisc.cmd} --name=#{Dvdvrconv::BASE_NAME} #{@vrdisc.opts_ifo} #{@vrdisc.opts_vro})
    end

    # Make a concatenation command string for FFmpeg.
    def str_concat_cmd(file_name, base_name)
      %(ffmpeg -f concat -safe 0 -i #{file_name} -c copy #{base_name}.vob)
    end

    # File convert command, vob to mp4 for FFmpeg.
    # * Change the aspect ratio to 16:9.
    # * Delete a closed caption.
    def ffmeg_normal_cmd(file_name)
      cmd = 'ffmpeg '
      cmd += "-i #{file_name}.vob "
      cmd += '-filter:v "crop=704:474:0:0" '
      cmd += '-vcodec libx264 '
      cmd += '-b:v 500k '
      cmd += '-aspect 16:9 '
      cmd += '-acodec copy '
      cmd += '-bsf:v "filter_units=remove_types=6" '
      cmd + "#{file_name}.mp4"
    end

    # File convert command, vob to mp4 for FFmpeg.
    # * FFmpeg with QSV(Intel Quick Sync Video)
    # * Change the aspect ratio to 16:9.
    # * Delete a closed caption.
    def ffmpeg_qsv_cmd(file_name)
      cmd = 'ffmpeg '
      cmd += '-hwaccel qsv '
      cmd += '-hwaccel_output_format qsv '
      cmd += "-i #{file_name}.vob "
      cmd += '-filter:v "crop=704:474:0:0" '
      cmd += '-c:v h264_qsv '
      cmd += '-global_quality:v 35 '
      cmd += '-look_ahead 1 '
      cmd += '-aspect 16:9 '
      cmd += '-acodec copy '
      cmd += '-bsf:v "filter_units=remove_types=6" '
      cmd + "#{file_name}.mp4"
    end

    # File convert command, vob to mp4 for FFmpeg.
    def str_convert_cmd(file_name)
      if @vrdisc.hardware_encode == 'qsv'
        ffmpeg_qsv_cmd(file_name)
      elsif @vrdisc.hardware_encode == 'normal'
        ffmeg_normal_cmd(file_name)
      else
        ffmeg_normal_cmd(file_name)
      end
    end

    # Read video information from dvd-ram discs in dvd-vr format.
    #
    # required values:
    #   @vrdisc.cmd, @vrdisc.opts_ifo
    #
    # Get values of the video information:
    #   => @vrdisc.header
    #   => @vrdisc.num
    #   => @vrdisc.title
    #   => @vrdisc.date
    #   => @vrdisc.size
    #
    def read_info
      out, err, status = Open3.capture3(@vrdisc.cmd, @vrdisc.opts_ifo)
      puts "File read error => #{err}" unless status.success?
      @vrdisc.header = out.scan(/^(.*?)Number/m)

      # Sets the captured information to @vrdisc.
      %w[num title date size].each do |item|
        str = format("%-5s", item) + ":"
        @vrdisc[item] = out.scan(/#{str}\s(.*?)$/)
      end

      out
    end

    # View video information from dvd-ram discs in dvd-vr format.
    #
    # required values:
    #   @vrdisc.header, @vrdisc.num, @vrdisc.title,
    #   @vrdisc.date, @vrdisc.size
    #
    def view_info
      puts '----- view dvd-vr info -----'
      puts @vrdisc.header
      [@vrdisc.num, @vrdisc.title, @vrdisc.date, @vrdisc.size].transpose.each do |x|
        %w[num title date size].each_with_index do |item, idx|
          line = format('%-5s', item) + ": #{x.flatten[idx].to_s}\n"
          puts line
        end
        puts '-'
      end
    end

    # Add sequence number to the duplicate title name.
    # Replace white space in the title with underscore.
    #
    # required value:
    #   @vrdisc.title
    #
    # Output values:
    #   => @vrdisc.duplicate_name
    #   => @vrdisc.output_title
    #
    def adjust_title
      output_title = []
      duplicate_names = []
      dup_counter = 0

      # Extract duplicate names from title.
      dup = @vrdisc.title.select { |x| @vrdisc.title.count(x) > 1 }

      @vrdisc.title.each_index do |idx|
        # Replace white space in the title with underscore.
        new_name = @vrdisc.title[idx][0].gsub(/\s/, "_")

        # Add sequential numbers to duplicate name.
        if dup.include?(@vrdisc.title[idx])
          dup_counter += 1
          output_title << format('%s_%02d', new_name, dup_counter)
          duplicate_names << new_name
        else
          output_title << format('%s', new_name)
        end
        dup_counter = 0 if dup_counter == @vrdisc.title.count(@vrdisc.title[idx])
      end

      @vrdisc.duplicate_name = duplicate_names.select do |x|
        duplicate_names.count(x) > 1
      end.uniq

      @vrdisc.output_title = output_title
    end

    # Read VRO file from dvd-ram disc in dvd-vr format, and output vob files.
    def vro2vob
      cmd = str_dvdvr_cmd
      puts '----- convert file VRO to VOB -----'
      puts "> cmd:\n  #{cmd}"
      system(cmd)
      puts ''
    end

    # Change the file name to the title name
    #
    # required value:
    #   @vrdisc.title
    #
    # Output values:
    #   => @vrdisc.vob_titles
    #
    def change_to_title_name
      vob_titles = []

      @vrdisc.title.size.times do |x|
        src = format('%s#%03d', Dvdvrconv::BASE_NAME, x + 1) + '.vob'
        dst = @vrdisc.output_title[x] + '.vob'
        vob_titles << [src, dst]
      end

      @vrdisc.vob_titles = vob_titles
    end

    # customize the title of vob files.
    #
    # If specify individual file names. Write "base_dst_name" as an Array.
    #
    #   base_dst_name = ["name_one", "name_two"]
    #   number_list = []
    #   => ["name_one", "name_two"]
    #
    # If add a sequence number to the file name. Write "base_dst_name" as String.
    #
    #   base_dst_name = "output_name_"
    #   number_list = []
    #   => ["output_name_01", "output_name_02", ...]
    #
    # If specify sequence numbers individually.
    # Write "base_dst_name" as String and Write "number_list" as an Array.
    #
    #   base_dst_name = "output_name_"
    #   number_list = [12, 13, 14, 15]
    #   => ["output_name_12", "output_name_13", "output_name_14", "output_name_15"]
    #
    # required Argument, value:
    #   base_dst_name, number_list,
    #   @vrdisc.title
    #
    # Output values:
    #   => @vrdisc.vob_titles
    #
    def customize_title(base_dst_name, number_list = [])
      vob_titles = []

      if @vrdisc.concat_mode == true
        titels = @vrdisc.title.uniq.flatten
      else
        titels = @vrdisc.output_title
      end

      titels.each_with_index do |title, idx|
        src = title.gsub(/\s/, '_') + '.vob'

        case base_dst_name
        when Array
          dst_name = base_dst_name[idx]
        when String
          if number_list.size.zero?
            dst_name = base_dst_name + format('_%02d', idx + 1)
          else
            case number_list[idx]
            when Numeric
              dst_name = base_dst_name + format('_%02d', number_list[idx])
            when String
              dst_name = base_dst_name + format('_%s', number_list[idx])
            end
          end
        end

        dst = dst_name + '.vob'
        vob_titles << [src, dst]
      end

      @vrdisc.vob_titles = vob_titles
    end

    # Rename vob file to a customized title name.
    #
    # @param [String] file_titles is Array. Includes pair of source and destination filename.
    #   *  [[src, dst], [src, dst], [src, dst], ....]
    #
    # required value:
    #   @vrdisc.vob_titles
    #
    def rename_vob
      puts '----- output vob file -----'

      @vrdisc.vob_titles.each do |file_title|
        src, dst = file_title

        if File.exist?("#{dst}")
          puts "Skip => file #{dst} is exist."
        else
          File.rename(src, dst)
          puts "  file name: #{dst}"
        end
      end
    end

    # Make a list of file names to concatenate.
    #
    # required values:
    #   @vrdisc.duplicate_name, @vrdisc.output_title
    #
    def make_concat_list
      concat_list = []

      @vrdisc.duplicate_name.each do |base_name|
        contents = ''
        file_name = "concat_#{base_name}.txt"

        names = @vrdisc.output_title.select { |x| x.match(/#{base_name}_\d\d/) }
        names.each { |line| contents += "file '#{line}.vob'\n" }
        concat_list << [file_name, contents, base_name]
      end

      concat_list
    end

    # Concatenate Split Titles.
    # This method uses FFmpeg's media file concatenation feature.
    #
    # required Argument:
    #   concat_list
    #
    # concat_list is Array. Includes file_name, contents, base_name.
    #
    #   concat_list = [[file_name, contents, base_name], [file_name, contents, base_name]. .... ]
    #
    # @param [String] file_name concat list name.
    # @param [String] contents concatenate file names.
    # @param [String] base_name output vob name.
    #
    def concat_titles(concat_list)
      puts '----- Concatenate Split Titles -----'
      concat_list.each do |list|
        file_name, contents, base_name = list
        File.write(file_name, contents)
        puts "concat list= #{file_name}"

        cmd = str_concat_cmd(file_name, base_name)
        puts '----- concat vob files -----'
        puts "run cmd:\n  #{cmd}"
        system(cmd)

        begin
          File.delete(file_name)
        rescue
          p $!
        end
      end
    end

    def vrdisc_status
      puts "\n< < < < < @vrdisc status > > > > >"
      %w[num title output_title duplicate_name vob_titles concat_mode hardware_encode].each do |item|
        puts "#{item}=> #{@vrdisc[item]}"
      end
      puts "< < < < < @vrdisc status > > > > >\n"
    end

    # convert vob to mp4.
    #
    # required Values:
    #   @vrdisc.vob_titles
    #
    def vob2mp4
      files = []

      @vrdisc.vob_titles.each do |vob_title|
        files << vob_title[1].gsub(/.vob/, '')
      end

      files.each do |file_name|
        if File.exist?("#{file_name}.mp4")
          puts "Skip => file #{file_name}.mp4 is exist."
        else
          cmd = str_convert_cmd(file_name)
          puts "----- convert #{file_name}.vob to mp4 file -----"
          puts "run cmd:\n  #{cmd}"
          system(cmd)
        end
      end
    end

    def debug_view_vrdisc
      @vrdisc.members.each do |member|
        puts "#{member} => #{@vrdisc[member]}"
      end
    end
  end
end

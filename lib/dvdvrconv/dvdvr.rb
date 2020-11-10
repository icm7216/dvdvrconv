module Dvdvrconv

  # DVD-VR disc status
  Vrdisc = Struct.new(
    :header,          # @param [String]
    :num,             # @param [Array<String>]
    :title,           # @param [Array<String>]
    :date,            # @param [Array<String>]
    :size,            # @param [Array<String>]
    :opts_ifo,        # @param [String]
    :opts_vro,        # @param [String]
    :cmd,             # @param [String]
    :output_title,    # @param [Array<String>]
    :duplicate_name,  # @param [Array<String>]
    :vob_titles,       # @param [Array<String>]
  )

  BASE_NAME = "DVD"

  class Dvdvr
    attr_accessor :vrdisc

    def initialize
      @vrdisc = Vrdisc.new(nil)

      if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin/
        @vrdisc.opts_ifo = "/cygdrive/D/DVD_RTAV/VR_MANGR.IFO"
        @vrdisc.opts_vro = "/cygdrive/D/DVD_RTAV/VR_MOVIE.VRO"
        @vrdisc.cmd = "win/dvd-vr.exe"
      else
        @vrdisc.opts_ifo = "/mnt/d/DVD_RTAV/VR_MANGR.IFO"
        @vrdisc.opts_vro = "/mnt/d/DVD_RTAV/VR_MOVIE.VRO"
        @vrdisc.cmd = "dvd-vr"
      end
    end

    # Read video information from dvd-ram discs in dvd-vr format.
    def read_info
      out, err, status = Open3.capture3(@vrdisc.cmd, @vrdisc.opts_ifo)
      @vrdisc.header = out.scan(/^(.*?)Number/m)

      # Sets the captured item to an instance variable.
      %w(num title date size).each do |item|
        str = format("%-5s", item) + ":"
        @vrdisc[item] = out.scan(/#{str}\s(.*?)$/)
      end

      out
    end

    # View video information from dvd-ram discs in dvd-vr format.
    def view_info
      puts "----- view dvd-vr info -----"
      puts @vrdisc.header
      [@vrdisc.num, @vrdisc.title, @vrdisc.date, @vrdisc.size].transpose.each do |x|
        %w(num title date size).each_with_index do |item, idx|
          line = format("%-5s", item) + ": #{x.flatten[idx].to_s}\n"
          puts line
        end
        puts "-"
      end
    end

    # Add sequence number to the duplicate title name.
    # Replace white space in the title with underscore.
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
          output_title << format("%s_%02d", new_name, dup_counter)
          duplicate_names << new_name
        else
          output_title << format("%s", new_name)
        end
        dup_counter = 0 if dup_counter == @vrdisc.title.count(@vrdisc.title[idx])
      end

      @vrdisc.duplicate_name = duplicate_names.select do |x|
        duplicate_names.count(x) > 1
      end.uniq

      @vrdisc.output_title = output_title
    end

    # Read VRO file from dvd-ram discs in dvd-vr format, and output vob files.
    def vro2vob
      cmd = %Q(#{@vrdisc.cmd} --name=#{Dvdvrconv::BASE_NAME} #{@vrdisc.opts_ifo} #{@vrdisc.opts_vro})
      puts "----- convert file VRO to VOB -----"
      puts "> cmd:\n  #{cmd}"
      system(cmd)
    end

    # customize the title of vob files.
    #
    # If specify individual file names. Write "base_dst_name" as an Array.
    #
    #   base_dst_name = ["name_one", "name_two"]
    #   number_list = []
    #
    # If add a sequence number to the file name. Write "base_dst_name" as an String.
    #
    #   base_dst_name = "output_name_"
    #   number_list = []
    #
    # If specify sequence numbers individually.
    # Write "base_dst_name" as an String and Write "number_list" as an Array.
    #
    #   base_dst_name = "output_name_"
    #   number_list = [12, 13, 14, 15]
    #
    def customize_title(base_dst_name, number_list = [])
      vob_titles = []

      base_dst_name.size.times do |x|
        break if x > @vrdisc.title.size - 1
        src = format("%s#%03d", Dvdvrconv::BASE_NAME, x + 1) + ".vob"

        case base_dst_name
        when Array
          dst_name = base_dst_name[x]
        when String
          if number_list.size.zero?
            dst_name = base_dst_name + format("_%02d", x + 1)
          else
            dst_name = base_dst_name + format("_%02d", number_list[x])
          end
        end

        dst = dst_name + ".vob"
        vob_titles << [src, dst]
      end

      @vrdisc.vob_titles = vob_titles
    end

    # Rename vob file to a customized title name.
    #
    # @param [String] file_titles is Array. Includes pair of source and destination filename.
    #   *  [[src, dst], [src, dst], [src, dst], ....]
    #
    def rename_vob
      puts "----- output vob file -----"

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
    def make_concat_list
      concat_list = []

      @vrdisc.duplicate_name.each do |base_name|
        contents = ""
        file_name = "concat_#{base_name}.txt"

        names = @vrdisc.output_title.select { |x| x.match(/#{base_name}_\d\d/) }
        names.each { |line| contents += %Q[file '#{line}.vob'\n] }
        concat_list << [file_name, contents, base_name]
      end

      concat_list
    end

    # Concatenate Split Titles.
    # This method uses FFmpeg's media file concatenation feature.
    #
    # concat_list is Array. Includes file_name, contents, base_name.
    #
    #   concat_list = [[file_name, contents, base_name], [file_name, contents, base_name]. .... ]
    #
    #   @param [String] file_name concat list name.
    #   @param [String] contents concatenate file names.
    #   @param [String] base_name output vob name.
    #
    def concat_titles(concat_list)
      puts "----- Concatenate Split Titles -----"
      concat_list.each do |list|
        file_name, contents, base_name = list
        File.write(file_name, contents)
        puts "concat list= #{file_name}"

        cmd = %Q[ffmpeg -f concat -safe 0 -i #{file_name} -c copy #{base_name}.vob]
        puts "----- concat vob files -----"
        puts "run cmd:\n  #{cmd}"
        system(cmd)

        begin
          File.delete(file_name)
        rescue
          p $!
        end
      end
    end

    # convert vob to mp4.
    #   * Change the aspect ratio to 16:9.
    #   * Delete a closed caption.
    def vob2mp4
      vob_titles = @vrdisc.title.uniq.map { |x| x[0].gsub(/\s/, "_") }

      vob_titles.each do |file_name|
        if File.exist?("#{file_name}.mp4")
          puts "Skip => file #{file_name}.mp4 is exist."
        else
          cmd = %Q[ffmpeg -i #{file_name}.vob -filter:v "crop=704:474:0:0" -vcodec libx264 -b:v 500k -aspect 16:9 -acodec copy -bsf:v "filter_units=remove_types=6" #{file_name}.mp4]
          puts "----- convert #{file_name}.vob to mp4 file -----"
          puts "run cmd:\n  #{cmd}"
          system(cmd)
        end
      end
    end
  end
end

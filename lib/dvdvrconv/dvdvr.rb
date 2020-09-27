module Dvdvrconv
  class Dvdvr
    attr_accessor :dvdvr_opts_ifo, :dvdvr_opts_vro
    attr_reader :num, :title, :date, :size, :base_name

    def initialize
      %w(header num title date size).each do |item|
        self.instance_variable_set("@#{item}", "")
      end

      @base_name = "DVD"

      if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin/
        @dvdvr_opts_ifo = "/cygdrive/D/DVD_RTAV/VR_MANGR.IFO"
        @dvdvr_opts_vro = "/cygdrive/D/DVD_RTAV/VR_MOVIE.VRO"
        @dvdvr_cmd = "win/dvd-vr.exe"
      else
        @dvdvr_opts_ifo = "/mnt/d/DVD_RTAV/VR_MANGR.IFO"
        @dvdvr_opts_vro = "/mnt/d/DVD_RTAV/VR_MOVIE.VRO"
        @dvdvr_cmd = "dvd-vr"
      end
    end

    def read_info
      # Read info from DVD-RAM
      out, err, status = Open3.capture3(@dvdvr_cmd, @dvdvr_opts_ifo)
      @header = out.scan(/^(.*?)Number/m)

      %w(num title date size).each do |item|
        str = format("%-5s", item) + ":"
        self.instance_variable_set("@#{item}", out.scan(/#{str}\s(.*?)$/))
      end

      out
    end

    def view_info
      puts "----- view dvd-vr info -----"
      puts @header
      [@num, @title, @date, @size].transpose.each do |x|
        %w(num title date size).each_with_index do |item, idx|
          line = format("%-5s", item) + ": #{x.flatten[idx].to_s}\n"
          puts line
        end
        puts "-"
      end
    end

    def adjust_title
      # Extract duplicate names from title
      dup = @title.select { |x| @title.count(x) > 1 }

      # Add sequential numbers to duplicate names
      output_title = []
      dup_counter = 0

      @title.each_index do |idx|
        # Replace white space in the title with underscore
        new_name = @title[idx][0].gsub(/\s/, "_")

        if dup.include?(title[idx])
          dup_counter += 1
          output_title << format("%s_%02d", new_name, dup_counter)
        else
          output_title << format("%s", new_name)
        end
        dup_counter = 0 if dup_counter == title.count(title[idx])
      end

      output_title
    end

    def vro2vob
      # read VRO file, and output vob files
      cmd = %Q(#{@dvdvr_cmd} --name=#{@base_name} #{@dvdvr_opts_ifo} #{@dvdvr_opts_vro})
      puts "----- convert file VRO to VOB -----"
      puts "> cmd:\n  #{cmd}"
      system(cmd)
    end

    def customize_title(base_dst_name, number_list = [])
      output_title = []

      base_dst_name.size.times do |x|
        break if x > @title.size - 1
        src = format("%s#%03d", @base_name, x + 1) + ".vob"

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
        output_title << [src, dst]
      end

      output_title
    end

    def rename_vob(file_titles)
      puts "----- output vob file -----"

      file_titles.each do |file_title|
        src, dst = file_title

        if File.exist?("#{dst}")
          puts "Skip => file #{dst} is exist."
        else
          File.rename(src, dst)
          puts "  file name: #{dst}"
        end
      end
    end
  end
end

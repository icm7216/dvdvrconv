module Dvdvrconv
  class Dvdvr
    attr_accessor :dvdvr_opts
    attr_reader :num, :title, :date, :size

    def initialize
      %w(header num title date size).each do |item|
        self.instance_variable_set("@#{item}", "")
      end

      if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin/
        @dvdvr_opts = "/cygdrive/D/DVD_RTAV/VR_MANGR.IFO"
        @dvdvr_cmd = "win/dvd-vr.exe"
      else
        @dvdvr_opts = "/mnt/d/DVD_RTAV/VR_MANGR.IFO"
        @dvdvr_cmd = "dvd-vr"
      end
    end

    def read_info
      # Read info from DVD-RAM
      out, err, status = Open3.capture3(@dvdvr_cmd, @dvdvr_opts)
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
  end
end

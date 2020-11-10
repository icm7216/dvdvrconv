module Dvdvrconv
  class Command
    def self.run(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv
    end

    # For now, this test code returns dummy dvd-vr information.
    def execute
      dvd = Dvdvrconv::Dvdvr.new
      # dvd.vrdisc.opts_ifo = "test/DVD_RTAV/VR_MANGR.IFO"
      # dvd.vrdisc.opts_vro = "test/DVD_RTAV/VR_MOVIE.VRO"
      dvd.read_info
      # dvd.view_info

      # Extract vob files
      dvd.adjust_title
      dvd.vro2vob

      # customize title of vob files
      base_dst_name = dvd.vrdisc.output_title
      dvd.customize_title(base_dst_name)
      dvd.rename_vob

      # Concatenate Split titles
      concat_list = dvd.make_concat_list
      dvd.concat_titles(concat_list)

      # convert vob to mp4
      dvd.vob2mp4
    end
  end
end

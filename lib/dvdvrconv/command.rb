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
      # dvd.dvdvr_opts_ifo = "test/DVD_RTAV/VR_MANGR.IFO"
      # dvd.dvdvr_opts_vro = "test/DVD_RTAV/VR_MOVIE.VRO"
      dvd.read_info
      # dvd.view_info

      # Extract vob files
      title, dup_name = dvd.adjust_title
      dvd.vro2vob

      # customize title of vob files
      vob_titles = dvd.customize_title(title)
      dvd.rename_vob(vob_titles)

      # Concatenate Split Titles
      concat_list = dvd.make_concat_list(title, dup_name)
      dvd.concat_titles(concat_list)

      # convert vob to mp4
      dvd.vob2mp4
    end
  end
end

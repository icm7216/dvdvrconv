module Dvdvrconv
  class Command
    def self.run(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv
    end

    # returm to dummy dvd-vr info for test command
    def execute
      # test command line
      dvd = Dvdvrconv::Dvdvr.new
      dvd.dvdvr_opts = "test/DVD_RTAV//VR_MANGR.IFO"
      dvd.read_info
      dvd.view_info
    end
  end
end

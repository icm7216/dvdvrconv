require "test_helper"

class DvdvrconvTest < Test::Unit::TestCase
  self.test_order = :defined

  sub_test_case "read dvd-vr info" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.vrdisc.opts_ifo = "test/DVD_RTAV/VR_MANGR.IFO"
      @dvd.read_info
      @num = @dvd.vrdisc.num
      @title = @dvd.vrdisc.title
      # @dvd.view_info
    end

    test "read num" do
      assert_equal [["1"], ["2"], ["3"]], @num
    end

    test "read title" do
      assert_equal [["TEST1"], ["TEST2"], ["TEST3"]], @title
    end
  end

  sub_test_case "Adjust title name" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.vrdisc.opts_ifo = "test/DVD_RTAV/VR_MANGR.IFO"
      @dvd.read_info
    end

    data(
      "Replace white space in the title with underscor" => [
        ["TEST_1", "TEST_2", "TEST_3"],
        [["TEST 1"], ["TEST 2"], ["TEST 3"]],
      ],
      "Add sequential numbers to duplicate names" => [
        ["TEST_01", "TEST_02", "TEST_03"],
        [["TEST"], ["TEST"], ["TEST"]],
      ],
      "Mixed white space and duplicate names" => [
        ["TEST_1", "TEST_2", "TEST_3", "T_EST_01", "T_EST_02", "T_EST_03", "foo_01", "foo_02", "foo_03"],
        [["TEST 1"], ["TEST 2"], ["TEST 3"], ["T EST"], ["T EST"], ["T EST"], ["foo"], ["foo"], ["foo"]],
      ],
    )

    def test_adjust_title(data)
      expected, target = data
      @dvd.vrdisc.title = target
      @dvd.adjust_title
      actual = @dvd.vrdisc.output_title
      assert_equal(expected, actual)
    end
  end

  sub_test_case "customize title name" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.vrdisc.opts_ifo = "test/DVD_RTAV//VR_MANGR.IFO"
      @dvd.read_info
    end

    data(
      "Specify individual file names." => [
        ["name_one.vob", "name_two.vob", "name_three.vob"],
        { base_dst_name: ["name_one", "name_two", "name_three"],
          number_list: [] },
      ],
      "Add sequence number." => [
        ["name_01.vob", "name_02.vob", "name_03.vob"],
        { base_dst_name: "name",
          number_list: [] },
      ],
      "Specify sequence numbers individually." => [
        ["name_11.vob", "name_12.vob", "name_13.vob"],
        { base_dst_name: "name",
          number_list: [11, 12, 13] },
      ],
    )

    def test_customize_title(data)
      expected, target = data
      base_dst_name = target[:base_dst_name]
      number_list = target[:number_list]
      titles = @dvd.customize_title(base_dst_name, number_list)
      actual = titles.transpose[1]
      assert_equal(expected, actual)
    end
  end

  sub_test_case "concat list" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
    end

    data(
      "make concat list for ffmpeg." => [
        [["concat_T_EST.txt",
          "file 'T_EST_01.vob'\nfile 'T_EST_02.vob'\nfile 'T_EST_03.vob'\n",
          "T_EST"],
         ["concat_foo.txt",
          "file 'foo_01.vob'\nfile 'foo_02.vob'\nfile 'foo_03.vob'\n",
          "foo"]],
        { output_title: ["TEST_1", "TEST_2", "TEST_3", "T_EST_01", "T_EST_02", "T_EST_03", "foo_01", "foo_02", "foo_03"],
          duplicate_name: ["T_EST", "foo"] },
      ],
    )

    def test_concat_list(data)
      expected, target = data
      @dvd.vrdisc.output_title = target[:output_title]
      @dvd.vrdisc.duplicate_name = target[:duplicate_name]
      actual = @dvd.make_concat_list
      assert_equal(expected, actual)
    end
  end

  sub_test_case "load YAML file" do
    test 'load from test dir' do
      config_file = {
        "vr_mangr_ifo" => "./test/DVD_RTAV/VR_MANGR.IFO",
        "vr_movie_vro" => "./test/DVD_RTAV/VR_MOVIE.VRO",
        "dvd_vr_cmd" => "./win/dvd-vr.exe"
      }
      stub(YAML).load {config_file}
      @dvdcmd = Dvdvrconv::Command.new(["-i"])
      @dvdcmd.load_config("./sample_default_dvdvrconv.yml")

      expected = {
        :vr_mangr_ifo => "./test/DVD_RTAV/VR_MANGR.IFO",
        :vr_movie_vro => "./test/DVD_RTAV/VR_MOVIE.VRO",
        :dvd_vr_cmd => "./win/dvd-vr.exe",
      }
      assert_equal expected, @dvdcmd.dvdpath
    end

    test 'undefined load directory' do
      config_file = {
        "dvd_vr_cmd" => "./win/dvd-vr.exe"
      }
      stub(YAML).load {config_file}
      @dvdcmd = Dvdvrconv::Command.new(["-i"])
      @dvdcmd.load_config("./sample_default_dvdvrconv.yml")

      expected = {
        :vr_mangr_ifo => nil,
        :vr_movie_vro => nil,
        :dvd_vr_cmd => "./win/dvd-vr.exe",
      }
      assert_equal expected, @dvdcmd.dvdpath
    end
  end
end

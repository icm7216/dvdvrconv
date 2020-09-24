require "test_helper"

class DvdvrconvTest < Test::Unit::TestCase
  self.test_order = :defined

  sub_test_case "read dvd-vr info" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.dvdvr_opts = "test/DVD_RTAV//VR_MANGR.IFO"
      @dvd.read_info
      @num = @dvd.num
      @title = @dvd.title
      # @dvd.view_info
    end

    test "read num" do
      assert_equal [["1"], ["2"], ["3"]], @num
    end

    test "read title" do
      assert_equal [["TEST1"], ["TEST2"], ["TEST3"]], @title
    end
  end

  sub_test_case "Replace white space in the title with underscore" do
    setup do
      dummy_title = [["TEST 1"], ["TEST 2"], ["TEST 3"]]

      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.dvdvr_opts = "test/DVD_RTAV//VR_MANGR.IFO"
      @dvd.read_info
      @dvd.instance_variable_set("@title", dummy_title)
    end

    test "read titles with underscore" do
      assert_equal ["TEST_1", "TEST_2", "TEST_3"], @dvd.adjust_title
    end
  end

  sub_test_case "Add sequential numbers to duplicate names" do
    setup do
      dummy_title = [["TEST"], ["TEST"], ["TEST"]]

      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.dvdvr_opts = "test/DVD_RTAV//VR_MANGR.IFO"
      @dvd.read_info
      @dvd.instance_variable_set("@title", dummy_title)
    end

    test "read titles with underscore" do
      assert_equal ["TEST_01", "TEST_02", "TEST_03"], @dvd.adjust_title
    end
  end
end

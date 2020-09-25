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

  sub_test_case "Adjust title name" do
    setup do
      @dvd = Dvdvrconv::Dvdvr.new
      @dvd.dvdvr_opts = "test/DVD_RTAV//VR_MANGR.IFO"
      @dvd.read_info
    end

    data(
      "Replace white space in the title with underscor" => [
        [["TEST 1"], ["TEST 2"], ["TEST 3"]],
        ["TEST_1", "TEST_2", "TEST_3"],
      ],
      "Add sequential numbers to duplicate names" => [
        [["TEST"], ["TEST"], ["TEST"]],
        ["TEST_01", "TEST_02", "TEST_03"],
      ],
      "Mixed white space and duplicate names" => [
        [["TEST 1"], ["TEST 2"], ["TEST 3"], ["T EST"], ["T EST"], ["T EST"], ["foo"], ["foo"], ["foo"]],
        ["TEST_1", "TEST_2", "TEST_3", "T_EST_01", "T_EST_02", "T_EST_03", "foo_01", "foo_02", "foo_03"],
      ],
    )

    def test_adjust_title(data)
      target, expected = data
      @dvd.instance_variable_set("@title", target)
      actual = @dvd.adjust_title
      assert_equal(expected, actual)
    end
  end
end

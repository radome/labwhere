require "test_helper"

class MigrateLabwaresTest < ActiveSupport::TestCase

  def setup
    MigrateTopLevelLocations.run!("test/fixtures")
    MigrateLocations.run!("test/fixtures")
    MigrateLabwares.run!("test/fixtures")
  end

  test "should migrate all of the labwares" do
    assert_operator Labware.all.count, :>, 0
    assert_equal CgapLabware.all.count, Labware.all.count
  end

  test "should be linked to the right location if labware has no row or column" do
    labwares = CgapLabware.where("row = 0  and column = 0")

    labware = labwares.first
    assert_equal Location.find(labware.cgap_location.labwhere_id), Labware.find_by_code(labware.barcode).location

    labware = labwares.last
    assert_equal Location.find(labware.cgap_location.labwhere_id), Labware.find_by_code(labware.barcode).location
  end

  test "should be in a coordinate and the correct location if labware has a row or column" do
    labwares = CgapLabware.where("row > 0 and column > 0")

    cgap_labware = labwares.first
    labware = Labware.find_by_code(cgap_labware.barcode)
    location = Location.find(cgap_labware.cgap_location.labwhere_id)
    assert location.labwares.include?(labware)
    assert_equal location.coordinates.find_by_position(row: cgap_labware.row, column: cgap_labware.column).labware, labware

    cgap_labware = labwares.last
    labware = Labware.find_by_code(cgap_labware.barcode)
    location = Location.find(cgap_labware.cgap_location.labwhere_id)
    assert location.labwares.include?(labware)
    assert_equal location.coordinates.find_by_position(row: cgap_labware.row, column: cgap_labware.column).labware, labware
  end

  def teardown
    CgapLocation.delete_all
    CgapLabware.delete_all
  end
  
end
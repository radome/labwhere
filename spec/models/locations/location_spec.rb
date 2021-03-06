#(l1) As a SM manager (Admin) I want to create new locations to enable RAS's track labware whereabouts.

require 'rails_helper'

RSpec.describe Location, type: :model do

  it "is invalid without a name" do
    expect(build(:location, name: nil)).to_not be_valid
  end

  it "is invalid without a location type" do
    expect(build(:location, location_type: nil)).to_not be_valid
  end

  it "is invalid if name is UNKNOWN" do
    expect(build(:location, name: "UNKNOWN")).to_not be_valid
    expect(build(:location, name: "unknown")).to_not be_valid
  end

  it "is invalid if is container and has a team" do
    expect(build(:location, container: 0, team: create(:team))).to_not be_valid
  end

  context "when location type has empty parent restriction" do

    before(:each) do
      restriction = create(:restriction, validator: EmptyParentValidator)
      @location_type = create(:location_type)
      @location_type.restrictions << restriction
    end

    it "is invalid with a parent" do
      location = build(:location_with_parent, location_type: @location_type)
      expect(location).to_not be_valid
    end

    it "is valid without a parent" do
      location = build(:location, location_type: @location_type)
      expect(location).to be_valid
    end
  end

  context "when location type has enforced parent types" do

    before(:each) do
      @restriction = create(:parentage_restriction, validator: ParentWhiteListValidator)
      @location_type = create(:location_type)
      @location_type.restrictions << @restriction
    end

    it "is valid with a parent that is one of the enforced types" do
      parent_location = build(:location, location_type: @restriction.location_types.first)
      location = build(:location, parent: parent_location, location_type: @location_type)

      expect(location).to be_valid
    end

    it "is invalid with a parent that is not one of the enforced location types" do
      parent_location = build(:location)
      location = build(:location, parent: parent_location, location_type: @location_type)

      expect(location).to_not be_valid
    end
  end

  context "when location type has restricted parent types" do

    before(:each) do
      @restriction = create(:parentage_restriction, validator: ParentBlackListValidator)
      @location_type = create(:location_type)
      @location_type.restrictions << @restriction
    end

    it "is valid when parent is not a restricted type" do
      location = build(:location_with_parent, location_type: @location_type)
      expect(location).to be_valid
    end

    it "is invalid when parent is a restricted type" do
      parent_location = build(:location, location_type: @restriction.location_types.first)
      location = build(:location, location_type: @location_type, parent: parent_location)
      expect(location).to_not be_valid
    end
  end

  it "#without_location should return a list of locations without a specified location" do
    locations         = create_list(:location, 3)
    inactive_location = create(:location, status: Location.statuses[:inactive])
    expect(Location.without(locations.last).count).to eq(2)
    expect(Location.without(locations.last)).to_not include(locations.last)
    expect(Location.without(locations.last)).to_not include(inactive_location)
  end

  it "#without_unknown should return all locations without UnknownLocation" do
    create_list(:location, 5)
    unknown_location = UnknownLocation.get
    expect(Location.without_unknown.count).to eq(5)
    expect(Location.without_unknown).to_not include(unknown_location)
  end

  it "#find_by_code should find a location by it's barcode" do
    location1 = create(:location)
    location2 = create(:location)
    expect(Location.find_by_code(location1.barcode)).to eq(location1)
  end

  it "name should not be valid with characters that aren't words, numbers, hyphens or spaces" do
    expect(build(:location, name: "location 1")).to be_valid
    expect(build(:location, name: "location one")).to be_valid
    expect(build(:location, name: "location-one")).to be_valid
    expect(build(:location, name: "location-one one")).to be_valid
    expect(build(:location, name: "A location +++")).to_not be_valid
    expect(build(:location, name: "A/location")).to_not be_valid
    expect(build(:location, name: "A location ~")).to_not be_valid
  end

  it "name should not be valid if it is more than 60 characters long" do
    expect(build(:location, name: "l"*59)).to be_valid
    expect(build(:location, name: "l"*60)).to be_valid
    expect(build(:location, name: "l"*61)).to_not be_valid
  end

  it "should be valid with brackets" do
    expect(build(:location, name: "(A location)")).to be_valid
  end

  it "barcode should be sanitised" do
    location = create(:location, name: "location1")
    expect(location.barcode).to eq("lw-location1-#{location.id}")
    location = create(:location, name: "location 1")
    expect(location.barcode).to eq("lw-location-1-#{location.id}")
    location = create(:location, name: "Location1")
    expect(location.barcode).to eq("lw-location1-#{location.id}")
  end

  it "#as_json should return the correct attributes" do
    location_type = create(:location_type, name: 'Building')
    location      = create(:location, location_type: location_type)
    json          = location.as_json
    expect(json["deactivated_at"]).to be_nil
    expect(json["created_at"]).to eq(location.created_at.to_s(:uk))
    expect(json["updated_at"]).to eq(location.updated_at.to_s(:uk))
    expect(json["location_type_id"]).to be_nil
    expect(json["location_type"]).to eq(location_type.name)
  end

  it "should add the parentage when a location is created" do
    location_1 = create(:location)
    expect(location_1.parentage).to be_blank

    location_2 = create(:location, parent: location_1)
    location_3 = create(:location, parent: location_2)
    expect(location_3.parentage).to eq("#{location_1.name} / #{location_2.name}")
  end

  it "should update the parentage when a parent is updated" do
    location_1 = create(:unordered_location)
    location_2 = create(:unordered_location)

    location_3 = create(:unordered_location, parent: location_1)
    location_4 = create(:unordered_location, parent: location_3)
    location_5 = create(:ordered_location, parent: location_4)

    location_3.update_attribute(:parent, location_2)
    expect(location_3.reload.parentage).to eq(location_2.name)
    expect(location_4.reload.parentage).to eq("#{location_2.name} / #{location_3.name}")
    expect(location_5.reload.parentage).to eq("#{location_2.name} / #{location_3.name} / #{location_4.name}")

  end

  it "#coordinateable? should determine if location has rows and columns" do
    expect(create(:location)).to_not be_coordinateable
    expect(create(:location, rows: 1, columns: 1)).to be_coordinateable
  end

  it "#transform should transform location to be the correct type and have the correct type attribute" do
    location_1 = build(:location)
    location_1 = location_1.transform
    expect(location_1).to be_unordered
    location_2 = build(:location, rows: 5, columns: 5)
    location_2 = location_2.transform
    expect(location_2).to be_ordered
  end

  it "#available_coordinates should be emtpy" do
    location = create(:location)
    expect(location.available_coordinates(5, 10)).to be_empty
  end

  it "#by_root should return locations which have no parent" do
    locations_with_parents = create_list(:location_with_parent, 3)
    locations_without_parents = create_list(:location, 3)
    expect(Location.by_root.count).to eq(6)
  end

  it '#should allow the same name with different parents' do

    parent_1 = create(:location, name: "Building1")
    parent_2 = create(:location, name: "Building2")

    expect(create(:location, name: 'Location', parent: parent_1)).to be_valid
    expect(create(:location, name: 'Location', parent: parent_2)).to be_valid
  end

  it '#should not allow the same name in the same parent' do
    parent = create(:location, name: "Building")

    expect(create(:location, name: 'Location', parent: parent)).to be_valid
    expect(build(:location, name: 'Location', parent: parent)).to_not be_valid
  end

  describe 'should have the correct child count' do
    it 'when empty' do
      expect(create(:location).child_count).to eq(0)
    end

    it 'with container children' do
      location = create(:unordered_location)
      location.children = create_list(:location, 2)

      expect(location.child_count).to eq(2)
    end

    it 'with labware children' do
      location = create(:location, parent: create(:location))
      location.labwares = create_list(:labware, 3)

      expect(location.child_count).to eq(3)
    end

    it 'with both container and labware children' do
      location = create(:unordered_location, parent: create(:location))
      location.children = create_list(:location, 2)
      location.labwares = create_list(:labware, 3)

      expect(location.child_count).to eq(5)
    end
  end

  describe '#has_child_locations?' do
    context 'when location has child locations' do
      it 'is true' do
        location = create(:unordered_location)
        location.children = create_list(:location, 3)
        expect(location.has_child_locations?).to eql(true)
      end
    end

    context 'when location has no child locations' do
      it 'is false' do
        expect(create(:location).has_child_locations?).to eql(false)
      end
    end
  end
  describe 'destroying locations' do
    it 'success' do
      location = create(:location)
      location.destroy
      expect(location).to be_destroyed
    end
    it 'failure' do
      location = create(:unordered_location_with_children)
      location.destroy
      expect(location).to_not be_destroyed
      location = create(:unordered_location_with_labwares)
      location.destroy
      expect(location).to_not be_destroyed
      location = create(:location_with_audits)
      location.destroy
      expect(location).to_not be_destroyed
    end
  end
end

require "rails_helper"

RSpec.describe Permissions::StandardPermission, type: :model do

  let(:permissions) { Permissions.permission_for(build(:standard))}

  it "should allow access to create a scan" do
    expect(permissions).to allow_permission(:scans, :create)
  end

  it "should not allow access to create or modify a location" do
    expect(permissions).to_not allow_permission(:locations, :create)
    expect(permissions).to_not allow_permission(:locations, :update)
  end

  it "should not allow access to create or modify a location type" do
    expect(permissions).to_not allow_permission(:location_types, :create)
    expect(permissions).to_not allow_permission(:location_types, :update)
  end

  it "should not allow access to create or modify a user" do
    expect(permissions).to_not allow_permission(:users, :create)
    expect(permissions).to_not allow_permission(:users, :update)
  end

  it "should not allow access to create or modify a team" do
    expect(permissions).to_not allow_permission(:teams, :create)
    expect(permissions).to_not allow_permission(:teams, :update)
  end

end
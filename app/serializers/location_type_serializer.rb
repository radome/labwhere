# Serializer for Location Type
# includes created_at and updated_at
class LocationTypeSerializer < ActiveModel::Serializer

  attributes :id, :name, :locations, :audits

  include SerializerDates
  include Rails.application.routes.url_helpers

  ##
  # Link to locations for current location type
  def locations
    api_location_type_locations_path(object)
  end

  ##
  # Link to audits for current location type
  def audits
    api_location_type_audits_path(object)

  end
end

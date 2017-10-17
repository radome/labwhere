##
# Serializer for the Labware
class LabwareSerializer < ActiveModel::Serializer

  attributes :barcode, :audits

  include SerializerDates
  include Rails.application.routes.url_helpers

  has_one :location

  ##
  # Link to the audits for the location
  def audits
    api_labware_audits_path(object.barcode)
  end

end

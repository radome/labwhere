# Serializer for Scan
# includes created_at and updated_at
class ScanSerializer < ActiveModel::Serializer

  attributes :message

  has_one :location

  include SerializerDates
  
end

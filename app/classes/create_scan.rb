##
# This will create a persisted scan.
# It can be used from a view or elsewhere.
# 
class CreateScan

  include ActiveModel::Model

  include HashAttributes

  attr_reader :scan
  attr_accessor :location_barcode, :labware_barcodes
  delegate :location, :message, to: :scan

  validate :check_for_errors

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "Scan")
  end

  def initialize
  end

  def submit(params)
    set_attributes(params)
    scan.location = Location.find_by(barcode: location_barcode)
    if valid?
      build_labwares
      scan.save
    else
      false
    end
  end

  def scan
    @scan ||= Scan.new
  end

private

  def build_labwares
    labware_barcodes.split("\n").each do |barcode|
      scan.labwares << Labware.find_or_initialize_by(barcode: barcode.remove_control_chars)
    end
  end

  def check_for_errors
    LocationValidator.new.validate(self)
  end
  
end
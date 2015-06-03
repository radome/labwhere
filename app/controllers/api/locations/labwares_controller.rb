class Api::Locations::LabwaresController < ApplicationController

  def index
    render json: current_resource, each_serializer: LocationLabwareSerializer
  end

private

  def current_resource
    Location.find_by_code(params[:location_barcode]).labwares if params[:location_barcode]
  end

end
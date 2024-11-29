class LocationsController < ApplicationController
  before_action { redirect_to url_for(zoom: 16) if params[:zoom].blank? }

  def show = render(inertia: "Map", props:)
  def records = Location.nearest_by_geohex(Geohex::Zone.decode(params[:id])).limit(50)

  def props
    Jbuilder.new do |json|
      json.key_format! camelize: :lower
      json.initial_zoom params[:zoom]
      json.initial_code params[:id]
      json.locations Location::Props.collection(view_context, records)
    end.attributes!
  end
end

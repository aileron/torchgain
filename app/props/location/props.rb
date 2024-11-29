class Location::Props < ApplicationProps
  def to_builder
    Jbuilder.new do |json|
      json.id record.id
      json.name record.name
      json.latitude record.latitude.to_f
      json.longitude record.longitude.to_f
    end
  end
end

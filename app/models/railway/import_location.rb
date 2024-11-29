module Railway::ImportLocation
  module_function

  def call
    ActiveRecord::Base.transaction do
      Railway::Station.find_each do |station|
        geohex = Geohex::Zone.encode(station.latitude.to_f, station.longitude.to_f, 10)
        Location.create(
          name: station.name,
          latitude: station.latitude,
          longitude: station.longitude,
          geohex_position: geohex.position,
          geohex:
        )
      end
    end
  end
end

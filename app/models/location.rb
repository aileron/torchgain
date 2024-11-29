class Location < ApplicationRecord
  before_create { self.id = "loc_#{ULID.generate}" }

  scope :nearest_by_geohex, lambda { |geohex|
    select(<<~SQL.squish, "*")
      ABS((geohex_position)[0] - #{geohex.x}) +
      ABS((geohex_position)[1] - #{geohex.y}) as hex_distance
    SQL
      .order("hex_distance ASC")
  }
end

require "ostruct"

#
# geohex/v3
#
# rubocop:disable Naming/MethodName, Metrics/ClassLength
class Geohex::Zone
  Position = Struct.new(:x, :y, keyword_init: true)
  Latlong = Struct.new(:lat, :lon, keyword_init: true)

  def deconstruct_keys(_) = { level:, x:, y:, latitude:, longitude: }
  def to_json(*options) = as_json.to_json(*options)
  def hex_size = @hex_size ||= H_BASE / (3**(level + 3))
  def unit_size = calcHexSize(level)

  def as_json(_options = nil)
    {
      code:,
      latitude:,
      longitude:,
      level:,
      x:,
      y:,
      unit_size:
    }
  end

  EARTH_RADIUS = 6371 # 地球の半径（km）
  H_KEY = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".freeze
  H_BASE = 20037508.34
  H_DEG = Math::PI * (30.0 / 180)
  H_K = Math.tan(H_DEG)

  DIRECTIONS = [
    [ 1, 0 ], [ 1, -1 ], [ 0, -1 ],
    [ -1, 0 ], [ -1, 1 ], [ 0, 1 ]
  ].freeze

  RING_3 =
    begin
      results = Set.new
      queue = [ [ 0, 0, 3 ] ] # [x, y, remaining_distance]

      until queue.empty?
        x, y, dist = queue.shift
        if dist.zero?
          results.add([ x, y ])
          next
        end

        DIRECTIONS.each do |dx, dy|
          nx = x + dx
          ny = y + dy
          queue.push([ nx, ny, dist - 1 ]) unless results.include?([ nx, ny ])
        end
      end

      results.to_a.sort_by { |x, y| (x * x) + (y * y) } # rubocop:todo Lint/ShadowingOuterLocalVariable
    end.freeze

  attr_reader :latitude, :longitude, :level, :code, :x, :y
  alias lat latitude
  alias lon longitude
  def position = [ x, y ]

  class << self
    def encode(latitude, longitude, level)
      instance = new
      instance.encode latitude, longitude, level
      instance
    end

    def decode(code)
      return if code.blank?

      instance = new
      instance.decode(code)

      instance
    end
  end

  def to_s = code
  def distance_to_geohex(geohex) = distance_to(self.class.decode(geohex))
  def deg2rad(deg) = deg * (Math::PI / 180)

  def distance_to(other_zone) # rubocop:todo Metrics/AbcSize
    dlat = deg2rad(other_zone.latitude - latitude)
    dlon = deg2rad(other_zone.longitude - longitude)

    a = (Math.sin(dlat / 2) * Math.sin(dlat / 2)) +
        (Math.cos(deg2rad(latitude)) * Math.cos(deg2rad(other_zone.latitude)) *
        Math.sin(dlon / 2) * Math.sin(dlon / 2))
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    EARTH_RADIUS * c # 距離（km）
  end

  def xy_distance_to(other_zone)
    dx = other_zone.x - x
    dy = other_zone.y - y
    Math.sqrt((dx**2) + (dy**2)) * unit_size / 1000 # 距離（km）
  end

  def ring_3
    RING_3.map do |(x, y)|
      new_x = self.x + x
      new_y = self.y + y

      getZoneByXY(new_x, new_y, level).last
    end
  end

  def calcHexSize(level)
    H_BASE / (3.0**(level + 3))
  end
  private :calcHexSize

  def loc2xy(lon, lat)
    x = lon * H_BASE / 180
    y = Math.log(Math.tan((90 + lat) * Math::PI / 360)) / (Math::PI / 180)
    y = y * H_BASE / 180

    Position.new x:, y:
  end

  def xy2loc(x, y)
    lon = (x / H_BASE) * 180
    lat = (y / H_BASE) * 180
    lat = 180.0 / Math::PI * ((2.0 * Math.atan(Math.exp(lat * Math::PI / 180))) - (Math::PI / 2))

    Latlong.new lon:, lat:
  end
  private :xy2loc

  def encode(latitude, longitude, level = 7) # rubocop:todo Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
    fail ArgumentError, "latitude must be between -90 and 90" unless (-90..90).cover? latitude
    fail ArgumentError, "longitude must be between -180 and 180" unless (-180..180).cover? longitude
    fail ArgumentError, "level must be between 0 and 15" unless (0..15).cover? level

    @level = level
    level += 2
    h_size = calcHexSize(@level)

    z_xy = loc2xy(longitude, latitude)
    lon_grid = z_xy.x
    lat_grid = z_xy.y
    unit_x = 6 * h_size
    unit_y = 6 * h_size * H_K
    h_pos_x = (lon_grid + (lat_grid / H_K)) / unit_x
    h_pos_y = (lat_grid - (H_K * lon_grid)) / unit_y
    h_x_0 = h_pos_x.floor
    h_y_0 = h_pos_y.floor
    h_x_q = h_pos_x - h_x_0
    h_y_q = h_pos_y - h_y_0
    h_x = h_pos_x.round
    h_y = h_pos_y.round

    if h_y_q > (-h_x_q) + 1
      if (h_y_q < 2 * h_x_q) && (h_y_q > 0.5 * h_x_q)
        h_x = h_x_0 + 1
        h_y = h_y_0 + 1
      end
    elsif h_y_q < (-h_x_q) + 1
      if (h_y_q > (2 * h_x_q) - 1) && (h_y_q < (0.5 * h_x_q) + 0.5)
        h_x = h_x_0
        h_y = h_y_0
      end
    end

    h_lat = ((H_K * h_x * unit_x) + (h_y * unit_y)) / 2
    h_lon = (h_lat - (h_y * unit_y)) / H_K

    z_loc = xy2loc(h_lon, h_lat)
    z_loc.lon
    z_loc.lat
    h_x, h_y = h_y, h_x if (H_BASE - h_lon) < h_size

    h_code = ""
    code3_x = []
    code3_y = []
    code3 = ""
    code9 = ""
    mod_x = h_x
    mod_y = h_y

    (level + 1).times do |i|
      h_pow = (3**(level - i))

      if mod_x >= (h_pow / 2.0).ceil
        code3_x << 2
        mod_x -= h_pow
      elsif mod_x <= -(h_pow / 2.0).ceil
        code3_x << 0
        mod_x += h_pow
      else
        code3_x << 1
      end

      if mod_y >= (h_pow / 2.0).ceil
        code3_y << 2
        mod_y -= h_pow
      elsif mod_y <= -(h_pow / 2.0).ceil
        code3_y << 0
        mod_y += h_pow
      else
        code3_y << 1
      end
    end

    code3_x.size.to_i.times do |i|
      code3 = "#{code3_x[i]}#{code3_y[i]}"
      code9 = code3.to_i(3).to_s
      h_code += code9.to_s
    end

    h_2  = h_code.slice(3, h_code.size).to_s
    h_1  = h_code.slice(0, 3).to_i
    h_a1 = (h_1 / 30).to_i
    h_a2 = h_1 % 30

    @code = "#{H_KEY.slice(h_a1, 1)}#{H_KEY.slice(h_a2, 1)}#{h_2}"
    @x = h_x
    @y = h_y
    @latitude = latitude
    @longitude = longitude

    @code
  end

  def decode(code) # rubocop:todo Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
    level = code.length
    @level = code.length - 2
    @unit_size = H_BASE / (3.0**level)

    calcHexSize(level)
    h_x = 0
    h_y = 0
    h_dec9 = ((H_KEY.index(code.slice(0, 1)) * 30) + H_KEY.index(code.slice(1, 1))).to_s + code.slice(2, code.length)

    if h_dec9.slice(0, 1).match(/[15]/) && h_dec9.slice(1, 1).match(/[^125]/) && h_dec9.slice(2, 1).match(/[^125]/)
      h_dec9 = if h_dec9.slice(0, 1) == "5"
                 "7#{h_dec9.slice(1, h_dec9.length)}"
      else
                 "3#{h_dec9.slice(1, h_dec9.length)}"
      end
    end

    d9xlen = h_dec9.length

    (level + 1 - d9xlen).times do
      h_dec9 = "0#{h_dec9}"
      d9xlen += 1
    end

    h_dec3 = ""
    d9xlen.times do |i|
      h_dec0 = h_dec9.slice(i, 1).to_i.to_s(3)

      h_dec3 += "0" if h_dec0.length == 1
      h_dec3 += h_dec0
    end

    h_decx = []
    h_decy = []

    (h_dec3.length / 2).times do |i|
      h_decx << h_dec3.slice(i * 2, 1)
      h_decy << h_dec3.slice((i * 2) + 1, 1)
    end

    (level + 1).times do |i|
      h_pow = (3**(level - i))
      case h_decx[i].to_i
      when 0
        h_x -= h_pow
      when 2
        h_x += h_pow
      end

      case h_decy[i].to_i
      when 0
        h_y -= h_pow
      when 2
        h_y += h_pow
      end
    end

    h_x, h_y, = adjust_xy h_x, h_y, @level

    @latitude, @longitude, @x, @y, @code = getZoneByXY h_x, h_y, @level

    [ @latitude, @longitude, @x, @y, @code ]
  end

  def getZoneByXY(x, y, level) # rubocop:todo Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
    h_size = calcHexSize(level)

    h_x = x
    h_y = y

    unit_x = 6 * h_size
    unit_y = 6 * h_size * H_K

    h_lat = ((H_K * h_x * unit_x) + (h_y * unit_y)) / 2
    h_lon = (h_lat - (h_y * unit_y)) / H_K

    z_loc = xy2loc(h_lon, h_lat)
    z_loc_x = z_loc.lon
    z_loc_y = z_loc.lat

    max_hsteps = 3**(level + 2)
    hsteps = (h_x - h_y).abs

    if hsteps == max_hsteps
      h_x, h_y = h_y, h_x if h_x > h_y
      z_loc_x = -180.0
    end

    h_code = ""
    code3_x = []
    code3_y = []
    code3 = ""
    code9 = ""
    mod_x = h_x
    mod_y = h_y

    (level + 3).times do |i|
      h_pow = 3**(level + 2 - i)
      if mod_x >= (h_pow / 2.0).ceil
        code3_x[i] = 2
        mod_x -= h_pow
      elsif mod_x <= -(h_pow / 2.0).ceil
        code3_x[i] = 0
        mod_x += h_pow
      else
        code3_x[i] = 1
      end

      if mod_y >= (h_pow / 2.0).ceil
        code3_y[i] = 2
        mod_y -= h_pow
      elsif mod_y <= -(h_pow / 2.0).ceil
        code3_y[i] = 0
        mod_y += h_pow
      else
        code3_y[i] = 1
      end

      if i == 2 && (z_loc_x == -180 || z_loc_x >= 0)
        if code3_x[0] == 2 && code3_y[0] == 1 && code3_x[1] == code3_y[1] && code3_x[2] == code3_y[2]
          code3_x[0] = 1
          code3_y[0] = 2
        elsif code3_x[0] == 1 && (code3_y[0]).zero? && code3_x[1] == code3_y[1] && code3_x[2] == code3_y[2]
          code3_x[0] = 0
          code3_y[0] = 1
        end
      end
    end

    code3_x.length.times do |i|
      code3 = "#{code3_x[i]}#{code3_y[i]}"
      code9 = code3.to_i(3).to_s
      h_code += code9.to_s
    end

    h_2 = h_code.slice(3, h_code.size).to_s
    h_1 = h_code.slice(0, 3).to_i
    h_a1 = (h_1 / 30).floor.to_i
    h_a2 = h_1 % 30

    code = "#{H_KEY.slice(h_a1)}#{H_KEY.slice(h_a2)}#{h_2}"

    [ z_loc_y, z_loc_x, h_x, h_y, code ]
  end
  private :getZoneByXY

  def adjust_xy(x, y, level)
    rev = 0
    max_hsteps = (3**(level + 2))
    hsteps = (x - y).abs

    if hsteps == max_hsteps && x > y
      x, y = y, x
      rev = 1
    elsif hsteps > max_hsteps
      dif = hsteps - max_hsteps
      dif_x = (dif / 2).floor
      dif_y = dif - dif_x

      if x > y
        edge_x = x - dif_x
        edge_y = y + dif_y
        edge_x, edge_y = edge_y, edge_x
        x = edge_x + dif_x
        y = edge_y - dif_y
      elsif y > x
        edge_x = x + dif_x
        edge_y = y - dif_y
        var h_xy = edge_x
        edge_x = edge_y
        edge_y = h_xy
        x = edge_x - dif_x
        y = edge_y + dif_y
      end
    end

    [ x, y, rev ]
  end
  private :adjust_xy
end
# rubocop:enable Naming/MethodName, Metrics/ClassLength

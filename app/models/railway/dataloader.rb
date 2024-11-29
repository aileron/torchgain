module Railway::Dataloader
  module_function

  def call
    ActiveRecord::Base.transaction do
      [ COMPANY_LOADER, LINE_LOADER, STATION_LOADER, LINK_LOADER ].each(&:call)
    end
  end

  def define(filename, table_name, column_mapping, &)
    lambda {
      truncate_table(table_name)
      copy_from_stdin(ActiveRecord::Base.connection.raw_connection, filename, table_name, column_mapping, &)
    }
  end

  def truncate_table(table_name)
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name} RESTART IDENTITY")
  end

  def copy_from_stdin(conn, filename, table_name, column_mapping, &block)
    conn.copy_data("COPY #{table_name} (#{column_mapping.values.join(', ')}) FROM STDIN WITH CSV HEADER") do
      CSV.foreach(Rails.root.join("app", "models", "railway", filename), headers: true) do |row|
        csv = row.to_h.transform_keys { column_mapping[_1] }
        block&.call(csv)
        conn.put_copy_data(column_mapping.values.map { |col| csv[col] }.to_csv)
      end
    end
  end

  COMPANY_LOADER = define(
    "company.csv",
    "railway_companies",
    {
      "company_cd" => "id",
      "rr_cd" => "rr_code",
      "company_name" => "name",
      "company_name_h" => "official_name",
      "company_name_r" => "short_name",
      "company_url" => "website_url",
      "company_type" => "category",
      "e_sort" => "sort"
    }
  )

  LINE_LOADER = define(
    "line.csv",
    "railway_lines",
    {
      "line_cd" => "id",
      "company_cd" => "company_id",
      "line_name" => "name",
      "line_name_k" => "kana",
      "line_name_h" => "official_name",
      "line_color_c" => "color",
      "lat" => "latitude",
      "lon" => "longitude",
      "zoom" => "zoom",
      "e_sort" => "sort",
      "e_status" => "status"
    }
  )

  STATION_LOADER = define(
    "station.csv",
    "railway_stations",
    {
      "station_cd" => "id",
      "station_g_cd" => "station_group_code",
      "line_cd" => "line_id",
      "station_name" => "name",
      "post" => "zipcode",
      "address" => "address",
      "lat" => "latitude",
      "lon" => "longitude",
      "e_sort" => "sort",
      "e_status" => "status",
      "pref_cd" => "prefecture_id",
      "geohex" => "geohex"
    }
  ) { |csv| csv["geohex"] = Geohex::Zone.encode(csv["latitude"].to_f, csv["longitude"].to_f, 10) }

  LINK_LOADER = define(
    "join.csv",
    "railway_links",
    {
      "line_cd" => "line_id",
      "station_cd1" => "station_id_1",
      "station_cd2" => "station_id_2"
    }
  )
end

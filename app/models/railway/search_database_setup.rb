module Railway::SearchDatabaseSetup
  module_function

  def call
    clear_dir
    prepare_work_dir
    prepare_dump_dir
    prepare_database
    create_tables
    create_index_tables
    index_all_stations
    dump_database
  end

  def clear_dir = FileUtils.rm_rf(File.dirname(database_path))
  def prepare_work_dir = FileUtils.mkdir_p(File.dirname(database_path))
  def prepare_dump_dir = FileUtils.mkdir_p(File.dirname(dump_path))
  def prepare_database = (create_database && chmod_database unless File.exist?(database_path))
  def index_all_stations = find_each_stations { add_station_to_index(_1) }
  def dump_path = Railway::SearchStation::DATABASE_FILE_PATH
  def database_path = Railway::SearchStation::DATABASE_WORK_PATH
  def create_database = Groonga::Database.create(path: database_path)
  def chmod_database = FileUtils.chmod(0o644, database_path)
  def find_each_stations = Railway::Station.where(status: 0).includes(line: :company).find_each { yield _1 }

  def dump_database
    File.open(dump_path, "w") do |file|
      context = Groonga::Context.new
      context.open_database(database_path)
      dumper = Groonga::DatabaseDumper.new(context:)
      file.write(dumper.dump)
    end
    FileUtils.chmod(0o644, dump_path)
  end

  def create_tables
    Groonga::Schema.create_table("Stations", type: :hash) do |table|
      table.short_text("name")
      table.short_text("line_name")
      table.short_text("company_name")
      table.text("address")
      table.text("content")
    end
  end

  def create_index_tables
    Groonga::Schema.create_table(
      "Terms",
      type: :patricia_trie,
      normalizer: :NormalizerAuto,
      default_tokenizer: :TokenDelimit
    ) do |table|
      table.index("Stations.name", with_position: true)
    end
  end

  def add_station_to_index(station)
    key = station.id
    line = station.line
    company = line&.company

    Groonga["Stations"].add(
      key,
      name: station.name,
      line_name: line&.name,
      company_name: company&.name,
      address: station.address,
      content: generate_search_content(station, line, company)
    )
  end

  def generate_search_content(station, line, company)
    [
      station.name,
      line&.name,
      line&.kana,
      company&.name,
      company&.short_name,
      station.address
    ].compact.join(" ")
  end
end

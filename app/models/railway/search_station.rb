module Railway
  class SearchStation
    include Singleton
    DATABASE_FILE_PATH = Rails.root.join("db/groonga/railway_stations.dump")
    DATABASE_WORK_PATH = Rails.root.join("tmp/groonga/railway_stations.dump")

    def self.query(query) = instance.search(query)
    def initialize = open_database
    def dump_path = DATABASE_FILE_PATH
    def database_path = DATABASE_WORK_PATH
    def database_exists? = File.exist?(database_path)
    def dump_exists? = File.exist?(dump_path)

    def search(query_string)
      results = Groonga["Stations"].select do |record|
        record.name.prefix_search(query_string)
      end
      results.sort([ { key: "_score", order: "descending" } ])
    end

    def open_database
      if database_exists?
        Groonga::Database.open(database_path)
      elsif dump_exists?
        restore_from_dump
      end
    rescue ::StandardError => e
      Bugsnag.notify(e)
      nil
    end

    def restore_from_dump
      FileUtils.mkdir_p(File.dirname(database_path))
      File.open(dump_path, "r") do |file|
        content = file.read
        context = Groonga::Context.new
        context.create_database(database_path)
        context.restore(content)
      end

      FileUtils.chmod(0o644, database_path)
      Groonga::Database.open(database_path)
    end
  end
end

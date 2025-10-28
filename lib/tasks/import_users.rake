namespace :users do
  desc "Import users and merchants from a CSV file"
  task :import, [ :file_path ] => :environment do |task, args|
    require "csv"

    unless args[:file_path]
      puts "❌ Error: Please provide a file path"
      puts "Usage: bin/rails users:import[path/to/users.csv]"
      exit 1
    end

    file_path = args[:file_path]

    puts "📁 Reading file: #{file_path}"
    puts "=" * 60

    begin
      importer = UserMerchantImporter.new(file_path)
      importer.import

      puts "=" * 60
      puts importer.summary
      puts importer.error_report if importer.errors.any?
      puts "=" * 60
      puts "✅ Import completed!"

      exit 1 unless importer.success?

    rescue ArgumentError => e
      puts "❌ Error: #{e.message}"
      exit 1
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end
end

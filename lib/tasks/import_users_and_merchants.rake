namespace :users do
  desc "Import users and merchants from a CSV file"
  task :import, [ :file_path ] => :environment do |task, args|
    unless args[:file_path]
      puts "❌ Error: Please provide a file path"
      puts "Usage: bin/rails users:import[path/to/users.csv]"
      exit 1
    end

    file_path = args[:file_path]

    puts "📁 Reading file: #{file_path}"
    puts "=" * 60

    begin
      orchestrator = Imports::Orchestrator.new(file_path)
      orchestrator.import

      puts "\n" + orchestrator.summary
      puts "=" * 60
      puts orchestrator.error_report

      if orchestrator.success?
        puts "\n✅ Import completed successfully!"
        exit 0
      else
        puts "\n⚠️  Import completed with errors"
        exit 1
      end
    rescue ArgumentError => e
      puts "\n❌ CSV structure error: #{e.message}"
      puts "🛑 Import stopped - please fix the CSV file"
      exit 1
    rescue => e
      puts "\n❌ Unexpected error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
end

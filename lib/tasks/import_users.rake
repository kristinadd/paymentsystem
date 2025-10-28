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

    unless File.exist?(file_path)
      puts "❌ Error: File not found: #{file_path}"
      exit 1
    end

    puts "📁 Reading file: #{file_path}"
    puts "=" * 60

    successful_imports = 0
    failed_imports = 0
    errors = []

    CSV.foreach(file_path, headers: true) do |row|
      begin
        user = User.create!(
          name: row["name"],
          email: row["email"],
          role: row["role"] # merchant or admin
        )

        if user.merchant? && row["merchant_name"].present?
          merchant = Merchant.create!(
            user: user,
            name: row["merchant_name"],
            email: row["merchant_email"],
            description: row["merchant_description"],
            active: true # creates all merchants with active status
          )
          puts "✅ Created user: #{user.name} (#{user.email}) with merchant: #{merchant.name}"
        else
          puts "✅ Created user: #{user.name} (#{user.email}) - #{user.role}"
        end

        successful_imports += 1

      rescue => e
        failed_imports += 1
        error_message = "#{row['email']}: #{e.message}"
        errors << error_message
        puts "❌ Failed: #{error_message}"
      end
    end

    puts "=" * 60
    puts "📊 IMPORT SUMMARY"
    puts "  Successful: #{successful_imports}"
    puts "  Failed: #{failed_imports}"
    puts "  Total: #{successful_imports + failed_imports}"

    if errors.any?
      puts "\n❌ Errors:"
      errors.each { |error| puts "  - #{error}" }
    end

    puts "=" * 60
    puts "✅ Import completed!"
  end
end

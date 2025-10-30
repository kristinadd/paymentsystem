namespace :api_keys do
  desc "Generate API keys for all existing merchants"
  task generate: :environment do
    puts "🔑 Generating API keys for merchants..."
    puts "=" * 60

    merchants = Merchant.all
    generated_count = 0

    merchants.each do |merchant|
      # Check if merchant already has an active API key
      if merchant.api_keys.active.exists?
        puts "📊 Merchant: #{merchant.name} (ID: #{merchant.id})"
        puts "   Email: #{merchant.email}"
        puts "   ⚠️  Already has an active API key. Skipping generation."
        puts ""
        next
      end

      result = ApiKeyGenerator.generate(merchant: merchant, name: "Default API Key for #{merchant.name}")
      raw_key = result[:raw_key]
      api_key_record = result[:api_key]

      puts "📊 Merchant: #{merchant.name}"
      puts "   Email: #{merchant.email}"
      puts "   🔑 API Key: #{raw_key}"
      puts "   ⚠️  SAVE THIS KEY - It won't be shown again!"
      puts ""
      generated_count += 1
    end

    puts "=" * 60
    puts "✅ Generated #{generated_count} API key(s)"

    puts "\n💡 Test with:"
    puts "   curl -X POST http://localhost:3000/api/v1/transactions \\"
    puts "     -H 'Content-Type: application/json' \\"
    puts "     -H 'Authorization: Bearer YOUR_API_KEY' \\"
    puts "     -d '{\"data\":{\"type\":\"authorize\",\"merchant_id\":1,\"amount\":100.50,\"customer_email\":\"test@example.com\",\"customer_phone\":\"1234567890\"}}'"
  end
end

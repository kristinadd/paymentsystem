namespace :transactions do
  desc "Delete transactions older than 1 hour"
  task cleanup: :environment do

    old_transactions = Transaction.where("created_at < ?", 1.hour.ago)
    count = old_transactions.count

    if count.zero?
      puts "✅ No transactions to delete"
    else
      puts "🗑️  Found #{count} transactions older than 1 hour"
      old_transactions.destroy_all
      puts "✅ Deleted #{count} transactions"
    end
  end
end

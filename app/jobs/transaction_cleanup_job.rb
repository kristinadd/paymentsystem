class TransactionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🧹 Starting transaction cleanup..."

    total_deleted = 0

    # Process in batches of 100, delete each batch with one query
    Transaction.where("created_at < ?", 1.hour.ago)
               .find_in_batches(batch_size: 100) do |batch|
      # Delete all records in this batch with one DELETE query
      deleted_count = Transaction.where(id: batch.map(&:id)).delete_all
      total_deleted += deleted_count

      Rails.logger.info "🗑️  Deleted batch of #{deleted_count} transactions"
    end

    if total_deleted.zero?
      Rails.logger.info "✅ No transactions to delete"
    else
      Rails.logger.info "🗑️  Deleted #{total_deleted} transactions older than 1 hour"
    end

    Rails.logger.info "🎉 Cleanup completed!"
    total_deleted
  end
end

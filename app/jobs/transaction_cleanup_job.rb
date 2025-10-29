class TransactionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    total_deleted = 0

    Transaction.where("created_at < ?", 1.hour.ago).find_each(batch_size: 100) do |transaction|
      transaction.destroy
      total_deleted += 1
    end

    Rails.logger.info "TransactionCleanupJob: Deleted #{total_deleted} old transactions"
    total_deleted
  end
end

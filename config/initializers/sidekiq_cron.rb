# Configure Sidekiq-Cron recurring jobs
# Only load this in non-test environments
unless Rails.env.test?
  Sidekiq::Cron::Job.create(
    name: "Delete old transactions",
    cron: "0 * * * *",  # Every hour at minute 0
    class: "TransactionCleanupJob"
  )
end

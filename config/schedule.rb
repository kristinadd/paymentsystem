# Set the output log path (optional)
set :output, "log/cron.log"

# Set environment (important for Rails)
set :environment, "development"

# Run transaction cleanup every hour
every 1.hour do
  rake "transactions:cleanup"
end

# Alternative schedules (commented out):
#
# Run every 30 minutes:
# every 30.minutes do
#   rake "transactions:cleanup"
# end
#
# Run at specific time every day:
# every 1.day, at: '3:00 am' do
#   rake "transactions:cleanup"
# end
#
# Run on specific days:
# every :monday, at: '9:00 am' do
#   rake "transactions:cleanup"
# end

# Learn more: http://github.com/javan/whenever

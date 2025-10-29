require 'rails_helper'
require 'rake'

RSpec.describe 'transactions:cleanup', type: :rake do
  before(:all) do
    Rails.application.load_tasks
  end

  after(:all) do
    Rake::Task.clear
  end

  let(:task) { Rake::Task['transactions:cleanup'] }

  before(:each) do
    task.reenable
  end

  describe 'cleanup old transactions' do
    let(:merchant) { create(:user, :with_merchant).merchant }

    context 'when there are old and new transactions' do
      before do
        # Old transactions (2 hours ago)
        3.times do
          create(:authorize_transaction, merchant: merchant, created_at: 2.hours.ago)
        end

        # New transactions (30 minutes ago)
        2.times do
          create(:authorize_transaction, merchant: merchant, created_at: 30.minutes.ago)
        end
      end

      it 'deletes only old transactions and keeps new ones' do
        expect {
          task.invoke
        }.to change(Transaction, :count).from(5).to(2)

        expect(Transaction.all).to all(have_attributes(created_at: be > 1.hour.ago))
      end
    end

    context 'when there are no old transactions' do
      before do
        create(:authorize_transaction, merchant: merchant, created_at: 30.minutes.ago)
      end

      it 'does not delete any transactions' do
        expect {
          task.invoke
        }.not_to change(Transaction, :count)
      end
    end

    context 'when there are no transactions' do
      it 'does not raise an error' do
        expect { task.invoke }.not_to raise_error
      end
    end
  end
end

require 'rails_helper'

RSpec.describe TransactionCleanupJob, type: :job do
  describe '#perform' do
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
          described_class.perform_now
        }.to change(Transaction, :count).from(5).to(2)

        expect(Transaction.all).to all(have_attributes(created_at: be > 1.hour.ago))
      end

      it 'returns the count of deleted transactions' do
        result = described_class.perform_now
        expect(result).to eq(3)
      end
    end

    context 'when there are no old transactions' do
      before do
        create(:authorize_transaction, merchant: merchant, created_at: 30.minutes.ago)
      end

      it 'does not delete any transactions' do
        expect {
          described_class.perform_now
        }.not_to change(Transaction, :count)
      end

      it 'returns zero' do
        result = described_class.perform_now
        expect(result).to eq(0)
      end
    end

    context 'when there are no transactions' do
      it 'does not raise an error' do
        expect { described_class.perform_now }.not_to raise_error
      end

      it 'returns zero' do
        result = described_class.perform_now
        expect(result).to eq(0)
      end
    end
  end
end

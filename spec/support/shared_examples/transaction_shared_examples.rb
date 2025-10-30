RSpec.shared_examples "enforces merchant status" do
  describe "merchant status requirements" do
    context "when merchant is active" do
      it "allows transaction creation" do
        active_merchant = create(:merchant)
        transaction = build_transaction_with_active_merchant(active_merchant)
        expect(transaction).to be_valid
      end
    end

    context "when merchant is inactive" do
      it "prevents transaction creation" do
        inactive_merchant = create(:merchant, :inactive)
        active_merchant = create(:merchant)
        transaction = build_transaction_with_inactive_merchant(inactive_merchant, active_merchant)

        expect(transaction).not_to be_valid
        expect(transaction.errors[:merchant]).to include("is not active")
      end
    end
  end
end

RSpec.shared_examples "prevents duplicate transactions" do
  describe "duplicate transaction prevention" do
    it "prevents creating multiple transactions for same parent" do
      parent = create_parent_transaction

      # First transaction - should succeed
      transaction1 = create_child_transaction(parent)
      expect(transaction1).to be_persisted

      # Reload parent to get updated status if needed
      parent.reload

      # Second transaction - should fail
      transaction2 = build_child_transaction(parent)
      expect(transaction2).not_to be_valid
      expect(transaction2.errors[:referenced_transaction]).to be_present
    end
  end
end

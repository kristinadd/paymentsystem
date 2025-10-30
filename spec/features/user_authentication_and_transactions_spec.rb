require "rails_helper"

RSpec.feature "User Authentication and Transactions", type: :feature do
  let!(:admin_user) { create(:user, role: :admin, email: "admin@example.com", name: "Admin User") }
  let!(:merchant_user) { create(:user, role: :merchant, email: "merchant@example.com", name: "Merchant User") }
  let!(:merchant) { create(:merchant, user: merchant_user, name: "Test Merchant") }
  let!(:other_merchant) { create(:merchant, name: "Other Merchant") }

  let!(:merchant_transaction) do
    create(:authorize_transaction, merchant: merchant, customer_email: "customer1@example.com")
  end

  let!(:other_transaction) do
    create(:authorize_transaction, merchant: other_merchant, customer_email: "customer2@example.com")
  end

  describe "Login Flow" do
    scenario "User can log in with email" do
      visit root_path

      # Should be redirected to login page
      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Login")
      expect(page).to have_field("Email Address")

      # Fill in email and submit
      fill_in "Email Address", with: "admin@example.com"
      click_button "Sign In"

      # Should be redirected to transactions page
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Welcome back, Admin User!")
      expect(page).to have_content("Transactions")
    end

    scenario "User sees error with invalid email" do
      visit login_path

      fill_in "Email Address", with: "nonexistent@example.com"
      click_button "Sign In"

      expect(page).to have_content("Invalid email")
      expect(page).to have_current_path(login_path)
    end
  end

  describe "Role-Based Access Control" do
    context "when logged in as Admin" do
      before do
        visit login_path
        fill_in "Email Address", with: admin_user.email
        click_button "Sign In"
      end

      scenario "Admin sees all transactions from all merchants" do
        visit transactions_path

        expect(page).to have_content("Viewing all transactions (Admin)")
        expect(page).to have_content("Admin User")
        expect(page).to have_content("Admin")

        # Should see both transactions
        expect(page).to have_content(merchant_transaction.uuid)
        expect(page).to have_content(other_transaction.uuid)
        expect(page).to have_content("customer1@example.com")
        expect(page).to have_content("customer2@example.com")
      end

      scenario "Admin can see transaction details in table" do
        visit transactions_path

        within("table") do
          expect(page).to have_content("UUID")
          expect(page).to have_content("Type")
          expect(page).to have_content("Merchant")
          expect(page).to have_content("Amount")
          expect(page).to have_content("Status")
          expect(page).to have_content("Customer Email")
          expect(page).to have_content("Authorize")
          expect(page).to have_content("Approved")
        end
      end
    end

    context "when logged in as Merchant" do
      before do
        visit login_path
        fill_in "Email Address", with: merchant_user.email
        click_button "Sign In"
      end

      scenario "Merchant sees only their own transactions" do
        visit transactions_path

        expect(page).to have_content("Viewing your transactions")
        expect(page).to have_content("Merchant User")
        expect(page).to have_content("Merchant")

        # Should see only their transaction
        expect(page).to have_content(merchant_transaction.uuid)
        expect(page).to have_content("customer1@example.com")

        # Should NOT see other merchant's transaction
        expect(page).not_to have_content(other_transaction.uuid)
        expect(page).not_to have_content("customer2@example.com")
      end

      scenario "Merchant sees their merchant name in transactions" do
        visit transactions_path

        within("table") do
          expect(page).to have_content(merchant.name)
          expect(page).to have_content(merchant.email)
        end
      end
    end
  end

  describe "Navigation" do
    before do
      visit login_path
      fill_in "Email Address", with: admin_user.email
      click_button "Sign In"
    end

    scenario "User sees navigation bar with user info" do
      visit transactions_path

      within("nav") do
        expect(page).to have_content("Payment System")
        expect(page).to have_content(admin_user.name)
        expect(page).to have_content("Admin")
        expect(page).to have_button("Logout")
      end
    end

    scenario "User can navigate to home from navbar" do
      visit transactions_path

      within("nav") do
        click_link "Payment System"
      end

      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Transactions")
    end
  end

  describe "Logout Flow" do
    before do
      visit login_path
      fill_in "Email Address", with: admin_user.email
      click_button "Sign In"
    end

    scenario "User can log out" do
      visit transactions_path

      within("nav") do
        click_button "Logout"
      end

      # Should be redirected to login page
      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Logged out successfully")
      expect(page).not_to have_content("Admin User")
    end

    scenario "After logout, user cannot access protected pages" do
      visit transactions_path

      within("nav") do
        click_button "Logout"
      end

      # Try to visit transactions page
      visit transactions_path

      # Should be redirected to login
      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Please log in to continue")
    end
  end

  describe "Transaction Display" do
    let!(:charge_transaction) do
      create(:charge_transaction,
             merchant: merchant,
             referenced_transaction: merchant_transaction,
             customer_email: "charged@example.com",
             amount: merchant_transaction.amount)
    end

    before do
      visit login_path
      fill_in "Email Address", with: merchant_user.email
      click_button "Sign In"
    end

    scenario "Shows transaction count badge" do
      visit transactions_path

      # Be more specific - look for the badge that contains "transactions"
      expect(page).to have_content("2 transactions")
    end

    scenario "Shows transaction with referenced transaction" do
      visit transactions_path

      within("table") do
        # Find the charge transaction row
        charge_row = page.find("tr", text: "Charge")

        within(charge_row) do
          expect(page).to have_content(charge_transaction.uuid)
          expect(page).to have_content(merchant_transaction.uuid) # Referenced TX
          expect(page).to have_content("charged@example.com")
        end
      end
    end

    scenario "Shows empty state when no transactions" do
      # Delete all transactions for this merchant (including the charge that references the authorize)
      merchant.transactions.each do |txn|
        txn.referencing_transactions.destroy_all
        txn.destroy
      end

      visit transactions_path

      expect(page).to have_content("No transactions found")
    end
  end
end

require "rails_helper"

RSpec.feature "Merchant Management", type: :feature do
  let!(:admin_user) { create(:user, role: :admin, email: "admin@example.com", name: "Admin User") }
  let!(:merchant_user) { create(:user, role: :merchant, email: "merchant@example.com", name: "Merchant User") }
  let!(:merchant) { create(:merchant, user: merchant_user, name: "Coffee Shop", description: "Best coffee in town") }
  let!(:other_merchant) { create(:merchant, name: "Book Store", description: "Rare books") }

  describe "Navigation" do
    before do
      login_as(admin_user)
    end

    scenario "User can navigate to merchants page from navbar" do
      visit root_path

      within("nav") do
        click_link "Merchants"
      end

      expect(page).to have_current_path(merchants_path)
      expect(page).to have_content("Merchants")
    end
  end

  describe "Role-Based Access Control" do
    context "when logged in as Admin" do
      before do
        login_as(admin_user)
      end

      scenario "Admin sees all merchants" do
        visit merchants_path

        expect(page).to have_content("Viewing all merchants (Admin)")
        expect(page).to have_content(admin_user.name)
        expect(page).to have_content("Admin")

        # Should see both merchants
        expect(page).to have_content(merchant.name)
        expect(page).to have_content(merchant.email)
        expect(page).to have_content(other_merchant.name)
        expect(page).to have_content(other_merchant.email)
      end

      scenario "Admin can see merchant details in table" do
        visit merchants_path

        within("table") do
          expect(page).to have_content("Name")
          expect(page).to have_content("Email")
          expect(page).to have_content("Description")
          expect(page).to have_content("Status")
          expect(page).to have_content("Total Transaction Sum")
          expect(page).to have_content("Best coffee in town")
          expect(page).to have_content("Active")
        end
      end
    end

    context "when logged in as Merchant" do
      before do
        login_as(merchant_user)
      end

      scenario "Merchant sees only their own merchant account" do
        visit merchants_path

        expect(page).to have_content("Your merchant account")
        expect(page).to have_content(merchant_user.name)
        expect(page).to have_content("Merchant")

        # Should see only their merchant
        expect(page).to have_content(merchant.name)
        expect(page).to have_content(merchant.email)
        expect(page).to have_content(merchant.description)

        # Should NOT see other merchant
        expect(page).not_to have_content(other_merchant.name)
        expect(page).not_to have_content(other_merchant.email)
      end

      scenario "Merchant sees merchant count badge" do
        visit merchants_path

        expect(page).to have_content("1 merchant")
      end
    end
  end

  describe "Merchant Display" do
    let!(:merchant_with_transactions) do
      m = create(:merchant, name: "Tech Store")
      auth_txn = create(:authorize_transaction, merchant: m, amount: 100, customer_email: "test@example.com")
      # Create a charge to actually increment total_transaction_sum
      create(:charge_transaction, merchant: m, referenced_transaction: auth_txn, amount: 100, customer_email: "test@example.com")
      m.reload
    end

    before do
      login_as(admin_user)
    end

    scenario "Shows merchant count badge for multiple merchants" do
      visit merchants_path

      expect(page).to have_content("merchants")
    end

    scenario "Shows merchant status badges" do
      inactive_merchant = create(:merchant, name: "Closed Shop", active: false)

      visit merchants_path

      within("table") do
        # Active merchant
        merchant_row = page.find("tr", text: merchant.name)
        within(merchant_row) do
          expect(page).to have_content("Active")
        end

        # Inactive merchant
        inactive_row = page.find("tr", text: inactive_merchant.name)
        within(inactive_row) do
          expect(page).to have_content("Inactive")
        end
      end
    end

    scenario "Shows total transaction sum" do
      visit merchants_path

      within("table") do
        merchant_row = page.find("tr", text: merchant_with_transactions.name)
        within(merchant_row) do
          expect(page).to have_content("$100.00")
        end
      end
    end

    scenario "Shows N/A for missing description" do
      merchant_without_desc = create(:merchant, name: "New Shop", description: nil)

      visit merchants_path

      within("table") do
        merchant_row = page.find("tr", text: merchant_without_desc.name)
        within(merchant_row) do
          expect(page).to have_content("N/A")
        end
      end
    end

    scenario "Shows empty state when no merchants" do
      # This scenario is for a merchant user with no merchant account
      merchant_user_without_merchant = create(:user, role: :merchant, email: "nommerchant@example.com")
      login_as(merchant_user_without_merchant)

      visit merchants_path

      expect(page).to have_content("No merchants found")
    end
  end

  describe "Delete Merchant" do
    context "when logged in as Admin" do
      before do
        login_as(admin_user)
      end

      scenario "Admin can delete a merchant" do
        visit merchants_path

        within("tr", text: merchant.name) do
          click_button "Delete"
        end

        expect(page).to have_current_path(merchants_path)
        expect(page).to have_content("Merchant '#{merchant.name}' was successfully deleted")

        # Merchant should not appear in the table
        within("table") do
          expect(page).not_to have_content(merchant.name)
        end
      end

      scenario "Admin sees delete buttons for all merchants" do
        visit merchants_path

        within("table") do
          expect(page).to have_button("Delete", count: Merchant.count)
        end
      end

      scenario "Cannot delete merchant with transactions" do
        merchant_with_txn = create(:merchant, name: "Shop with Transactions")
        create(:authorize_transaction, merchant: merchant_with_txn, customer_email: "test@example.com")

        visit merchants_path

        within("tr", text: merchant_with_txn.name) do
          click_button "Delete"
        end

        expect(page).to have_content("Cannot delete merchant")
        expect(page).to have_content(merchant_with_txn.name)
      end
    end

    context "when logged in as Merchant" do
      before do
        login_as(merchant_user)
      end

      scenario "Merchant can delete their own merchant account" do
        visit merchants_path

        within("tr", text: merchant.name) do
          click_button "Delete"
        end

        expect(page).to have_current_path(merchants_path)
        expect(page).to have_content("Merchant '#{merchant.name}' was successfully deleted")
        expect(page).to have_content("No merchants found")
      end

      scenario "Merchant cannot delete other merchants" do
        visit merchants_path

        # Should only see their own merchant
        expect(page).to have_button("Delete", count: 1)
        expect(page).not_to have_content(other_merchant.name)
      end
    end
  end

  describe "Update Merchant" do
    context "when logged in as Admin" do
      before do
        login_as(admin_user)
      end

      scenario "Admin can update a merchant" do
        visit merchants_path

        within("tr", text: merchant.name) do
          click_link "Edit"
        end

        expect(page).to have_current_path(edit_merchant_path(merchant))
        expect(page).to have_content("Edit Merchant")

        fill_in "Merchant Name", with: "Updated Coffee Shop"
        fill_in "Email Address", with: "updated@example.com"
        fill_in "Description", with: "Updated description"
        click_button "Update Merchant"

        expect(page).to have_current_path(merchants_path)
        expect(page).to have_content("Merchant 'Updated Coffee Shop' was successfully updated")
        expect(page).to have_content("Updated Coffee Shop")
        expect(page).to have_content("updated@example.com")
        expect(page).to have_content("Updated description")
      end

      scenario "Admin sees validation errors on invalid update" do
        visit edit_merchant_path(merchant)

        fill_in "Merchant Name", with: ""
        fill_in "Email Address", with: "invalid-email"
        click_button "Update Merchant"

        expect(page).to have_content("error")
        expect(page).to have_content("Name can't be blank")
        expect(page).to have_content("Email is invalid")
      end

      scenario "Admin sees Edit buttons for all merchants" do
        visit merchants_path

        within("table") do
          expect(page).to have_link("Edit", count: Merchant.count)
        end
      end
    end

    context "when logged in as Merchant" do
      before do
        login_as(merchant_user)
      end

      scenario "Merchant can update their own merchant account" do
        visit merchants_path

        within("tr", text: merchant.name) do
          click_link "Edit"
        end

        expect(page).to have_current_path(edit_merchant_path(merchant))

        fill_in "Merchant Name", with: "My Updated Shop"
        fill_in "Description", with: "New and improved"
        click_button "Update Merchant"

        expect(page).to have_current_path(merchants_path)
        expect(page).to have_content("Merchant 'My Updated Shop' was successfully updated")
        expect(page).to have_content("My Updated Shop")
        expect(page).to have_content("New and improved")
      end

      scenario "Merchant cannot edit other merchants" do
        visit merchants_path

        # Should only see their own merchant
        expect(page).to have_link("Edit", count: 1)
        expect(page).not_to have_content(other_merchant.name)
      end

      scenario "Merchant can cancel editing" do
        visit edit_merchant_path(merchant)

        click_link "Cancel"

        expect(page).to have_current_path(merchants_path)
      end
    end
  end
end

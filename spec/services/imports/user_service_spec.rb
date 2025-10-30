require 'rails_helper'

RSpec.describe Imports::UserService, type: :service do
  let(:valid_row) do
    {
      "name" => "John Doe",
      "email" => "john@example.com",
      "role" => "admin"
    }
  end

  describe '#call' do
    context 'with valid data' do
      it 'creates a user' do
        service = Imports::UserService.new(valid_row)

        expect {
          service.call
        }.to change(User, :count).by(1)
      end

      it 'returns the created user' do
        service = Imports::UserService.new(valid_row)
        user = service.call

        expect(user).to be_a(User)
        expect(user.name).to eq("John Doe")
        expect(user.email).to eq("john@example.com")
        expect(user.role).to eq("admin")
        expect(user).to be_persisted
      end
    end

    context 'with invalid data' do
      it 'returns nil when user creation fails' do
        invalid_row = valid_row.merge("email" => "invalid-email")
        service = Imports::UserService.new(invalid_row)

        user = service.call

        expect(user).to be_nil
        expect(service.errors).not_to be_empty
      end

      it 'does not create user when email validation fails' do
        invalid_row = valid_row.merge("email" => "not-an-email")
        service = Imports::UserService.new(invalid_row)

        expect {
          service.call
        }.not_to change(User, :count)
      end
    end

    context 'with missing required fields' do
      it 'raises error when name is missing' do
        row = valid_row.merge("name" => "")
        service = Imports::UserService.new(row)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Name is required")
      end

      it 'raises error when email is missing' do
        row = valid_row.merge("email" => "")
        service = Imports::UserService.new(row)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Email is required")
      end

      it 'raises error when role is missing' do
        row = valid_row.merge("role" => "")
        service = Imports::UserService.new(row)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Role is required")
      end
    end
  end
end

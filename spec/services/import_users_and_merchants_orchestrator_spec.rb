require 'rails_helper'

RSpec.describe ImportUsersAndMerchantsOrchestrator, type: :service do
  let(:valid_csv_path) { Rails.root.join('spec', 'fixtures', 'files', 'valid_users.csv') }
  let(:invalid_csv_path) { Rails.root.join('spec', 'fixtures', 'files', 'invalid_users.csv') }
  let(:missing_csv_path) { Rails.root.join('spec', 'fixtures', 'files', 'missing.csv') }

  before do
    # Create valid CSV
    FileUtils.mkdir_p(Rails.root.join('spec', 'fixtures', 'files'))
    File.write(valid_csv_path, valid_csv_content)
  end

  after do
    # Clean up test files
    FileUtils.rm_f(valid_csv_path)
    FileUtils.rm_f(invalid_csv_path)
  end

  let(:valid_csv_content) do
    <<~CSV
      name,email,role,merchant_name,merchant_email,merchant_description
      John Admin,john.admin@example.com,admin
      Jane Merchant,jane.merchant@example.com,merchant,Jane's Coffee Shop,coffee@example.com,Premium coffee
      Bob Admin,bob.admin@example.com,admin
    CSV
  end

  describe '#import' do
    context 'with valid CSV' do
      it 'creates users and merchants' do
        orchestrator = described_class.new(valid_csv_path)

        expect {
          orchestrator.import
        }.to change(User, :count).by(3)
         .and change(Merchant, :count).by(1)
      end

      it 'tracks successful creations' do
        orchestrator = described_class.new(valid_csv_path)
        orchestrator.import

        expect(orchestrator.results[:users_created]).to eq(3)
        expect(orchestrator.results[:merchants_created]).to eq(1)
        expect(orchestrator.results[:users_failed]).to eq(0)
        expect(orchestrator.results[:merchants_failed]).to eq(0)
      end

      it 'returns success status' do
        orchestrator = described_class.new(valid_csv_path)
        orchestrator.import

        expect(orchestrator.success?).to be true
      end
    end

    context 'with invalid user data' do
      before do
        invalid_content = <<~CSV
          name,email,role,merchant_name,merchant_email,merchant_description
          John Admin,invalid-email,admin
          Jane Merchant,jane@example.com,merchant,Jane's Coffee,coffee@example.com,Test
        CSV
        File.write(invalid_csv_path, invalid_content)
      end

      it 'skips invalid rows and continues' do
        orchestrator = described_class.new(invalid_csv_path)

        expect {
          orchestrator.import
        }.to change(User, :count).by(1)  # Only Jane is created
      end

      it 'tracks failed creations' do
        orchestrator = described_class.new(invalid_csv_path)
        orchestrator.import

        expect(orchestrator.results[:users_created]).to eq(1)
        expect(orchestrator.results[:users_failed]).to eq(1)
        expect(orchestrator.results[:errors].size).to eq(1)
      end

      it 'returns failure status' do
        orchestrator = described_class.new(invalid_csv_path)
        orchestrator.import

        expect(orchestrator.success?).to be false
      end
    end

    context 'with invalid merchant data' do
      before do
        invalid_content = <<~CSV
          name,email,role,merchant_name,merchant_email,merchant_description
          Jane Merchant,jane@example.com,merchant,Jane's Coffee,invalid-email,Test
        CSV
        File.write(invalid_csv_path, invalid_content)
      end

      it 'creates user but skips invalid merchant' do
        orchestrator = described_class.new(invalid_csv_path)

        expect {
          orchestrator.import
        }.to change(User, :count).by(1)
         .and change(Merchant, :count).by(0)
      end

      it 'tracks merchant failures' do
        orchestrator = described_class.new(invalid_csv_path)
        orchestrator.import

        expect(orchestrator.results[:users_created]).to eq(1)
        expect(orchestrator.results[:merchants_failed]).to eq(1)
      end
    end

    context 'with merchant role but no merchant data' do
      before do
        content = <<~CSV
          name,email,role,merchant_name,merchant_email,merchant_description
          Jane Merchant,jane@example.com,merchant
        CSV
        File.write(invalid_csv_path, content)
      end

      it 'creates user but skips merchant creation' do
        orchestrator = described_class.new(invalid_csv_path)

        expect {
          orchestrator.import
        }.to change(User, :count).by(1)
         .and change(Merchant, :count).by(0)
      end

      it 'does not track as merchant failure' do
        orchestrator = described_class.new(invalid_csv_path)
        orchestrator.import

        expect(orchestrator.results[:merchants_failed]).to eq(0)
      end
    end

    context 'with missing file' do
      it 'raises error' do
        orchestrator = described_class.new(missing_csv_path)

        expect {
          orchestrator.import
        }.to raise_error(ArgumentError, /File not found/)
      end
    end

    context 'with blank file path' do
      it 'raises error' do
        orchestrator = described_class.new("")

        expect {
          orchestrator.import
        }.to raise_error(ArgumentError, "File path cannot be blank")
      end
    end
  end

  describe '#summary' do
    it 'returns formatted summary' do
      orchestrator = described_class.new(valid_csv_path)
      orchestrator.import
      summary = orchestrator.summary

      expect(summary).to include("Users created: 3")
      expect(summary).to include("Merchants created: 1")
      expect(summary).to include("Total rows processed: 3")
    end
  end

  describe '#error_report' do
    context 'with no errors' do
      it 'returns success message' do
        orchestrator = described_class.new(valid_csv_path)
        orchestrator.import

        expect(orchestrator.error_report).to eq("No errors! 🎉")
      end
    end

    context 'with errors' do
      before do
        invalid_content = <<~CSV
          name,email,role,merchant_name,merchant_email,merchant_description
          John Admin,invalid-email,admin
        CSV
        File.write(invalid_csv_path, invalid_content)
      end

      it 'returns formatted error list' do
        orchestrator = described_class.new(invalid_csv_path)
        orchestrator.import
        report = orchestrator.error_report

        expect(report).to include("Errors:")
        expect(report).to include("Line 2:")
      end
    end
  end
end

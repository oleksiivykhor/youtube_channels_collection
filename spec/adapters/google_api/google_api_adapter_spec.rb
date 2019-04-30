require 'rails_helper'

RSpec.describe GoogleAPI::GoogleAPIAdapter do
  let(:adapter) { described_class.new('request', 5) }

  it { expect(adapter.results.count).to eq 5 }

  context 'when Google::Apis::ClientError was raised' do
    before do
      allow(adapter).to receive(:service).
        and_raise Google::Apis::ClientError, 'error'
    end

    it 'returns the empty results' do
      expect(adapter.results).to be_empty
    end
  end

  context 'when API needs to approve access the first time' do
    before do
      allow_any_instance_of(Google::Auth::UserAuthorizer).
        to receive(:get_credentials)
    end

    it 'approves and saves credentials' do
      expect(adapter).to receive(:store_credentials).and_call_original
      expect { adapter.results }.not_to raise_error
    end
  end
end

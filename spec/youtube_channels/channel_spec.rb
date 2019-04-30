require 'rails_helper'

RSpec.describe YoutubeChannels::Channel do
  let(:channel) { described_class.new(data) }
  let(:email) { 'some_email@example.com' }
  let(:data) do
    {
      snippet: {
        title: 'test title',
        description: "test description with email #{email}  "
      },
      statistics: { subscriberCount: '20' }
    }
  end

  it { expect(channel.title).to eq data[:snippet][:title] }
  it { expect(channel.description).to eq data[:snippet][:description] }
  it { expect(channel.email).to eq email }
  it do
    expect(channel.subscribers_amount).to eq data[:statistics][:subscriberCount]
  end

  context 'when email is not present in the description' do
    let(:email) { nil }

    it 'returns email as nil' do
      expect(channel.email).to be_nil
    end
  end

  context 'when channel descritpion contains more than one email address' do
    let(:email) { 'first@email.com, second@email.com' }
    before { data[:snippet][:description] = email }

    it 'returns correct email' do
      expect(channel.email).to eq email
    end
  end

  context 'when channel description contains duplicate emails' do
    let(:email) { 'first@email.com, second@email.com' }

    before { data[:snippet][:description] = "#{email} #{email}" }

    it 'returns correct email' do
      expect(channel.email).to eq email
    end
  end
end

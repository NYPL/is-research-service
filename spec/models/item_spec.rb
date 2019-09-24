require 'spec_helper'
require 'webmock/rspec'

describe Item do
  test_items = [
    {
      item: Item.new("sierra-nypl", "37314241"),
      result: false
    },
    {
      item: Item.new("recap-pul", "6739525"),
      result: true
    },
  ]

  before(:each) do
    ENV['PLATFORM_API_BASE_URL'] = 'https://example.com/api/v0.1/'
    ENV['NYPL_OAUTH_ID'] = Base64.strict_encode64 'fake-client'
    ENV['NYPL_OAUTH_SECRET'] = Base64.strict_encode64 'fake-secret'
    ENV['NYPL_OAUTH_URL'] = 'https://isso.example.com/'

    $platform_api = PlatformApiClient.new
    $nypl_core = NyplCore.new

    KmsClient.aws_kms_client.stub_responses(:decrypt, -> (context) {
      # "Decrypt" by subbing "encrypted" with "decrypted" in string:
      { plaintext: context.params[:ciphertext_blob].gsub('encrypted', 'decrypted') }
    })

    $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')

    stub_request(:get, "https://s3.amazonaws.com/nypl-core-objects-mapping-production/by_catalog_item_type.json")
    .with(
      headers: {
       	'Accept'=>'*/*',
       	'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	'User-Agent'=>'Ruby'
      }
    )
    .to_return(status: 200, body: File.read("./spec/fixtures/by_catalog_item_type.json"))

    stub_request(:get, "https://s3.amazonaws.com/nypl-core-objects-mapping-production/by_sierra_location.json")
    .with(
      headers: {
     	  'Accept'=>'*/*',
     	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
     	  'User-Agent'=>'Ruby'
      }
    )
    .to_return(status: 200, body: File.read("./spec/fixtures/by_sierra_location.json"), headers: {})

    stub_request(:post, "#{ENV['NYPL_OAUTH_URL']}oauth/token").to_return(status: 200, body: '{ "access_token": "fake-access-token" }')

    test_items.each do |test_item|
      stub_request(:get,
        "#{ENV['PLATFORM_API_BASE_URL']}items/#{test_item[:item].nypl_source}/#{test_item[:item].id}").to_return(status: 200, body: File.read("./spec/fixtures/item_#{test_item[:item].id}.json")
      )
    end
  end

  describe "#is_research" do
    it "should declare partner items as research" do
      item = test_items[1][:item]
      expect(item.is_research).to eq(true)
    end

    it "should declare branch items as not research" do
      item = test_items[0][:item]
      expect(item.is_research).to eq(false)
    end
  end
end

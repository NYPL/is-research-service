require 'spec_helper'

describe Bib do
  partner_record = Bib.new("recap-pul", "7843570")
  bib_with_research_item = Bib.new("sierra-nypl", "17906651")
  mixed_bib = Bib.new("sierra-nypl", "10036259")
  zero_item_bib = Bib.new("sierra-nypl", "12345678")
  deleted_bib = Bib.new('sierra-nypl', '19060447')

  before(:each) do
    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_catalog_item_type.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_catalog_item_type.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_sierra_location.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_sierra_location.json"))

    stub_request(:post, "#{ENV['NYPL_OAUTH_URL']}oauth/token").to_return(status: 200, body: '{ "access_token": "fake-access-token" }')

    $platform_api = PlatformApiClient.new
    $nypl_core = NyplCore.new
    $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
    $mixed_bib_ids = File.read('data/mixed-bibs.csv')
    .split("\n")
    .map { |bnum| bnum.strip.sub(/^b/, '').chop }

    KmsClient.aws_kms_client.stub_responses(:decrypt, -> (context) {
      # "Decrypt" by subbing "encrypted" with "decrypted" in string:
      { plaintext: context.params[:ciphertext_blob].gsub('encrypted', 'decrypted') }
    })

    [partner_record, bib_with_research_item, mixed_bib].each do |test_bib|
      stub_request(:get,
        "#{ENV['PLATFORM_API_BASE_URL']}bibs/#{test_bib.nypl_source}/#{test_bib.id}/items").to_return(status: 200, body: File.read("./spec/fixtures/bib_items_#{test_bib.id}.json")
      )
    end

    # this end point returns 404 for bib with no items
    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}bibs/sierra-nypl/12345678/items").to_return(status: 404, body: File.read("./spec/fixtures/sierra_404.json")
    )

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}bibs/sierra-nypl/12345678").to_return(status: 200, body: File.read("./spec/fixtures/bib_12345678.json")
    )

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}bibs/sierra-nypl/19060447/items").to_return(status: 404, body: File.read("./spec/fixtures/sierra_404.json")
    )

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}bibs/sierra-nypl/19060447").to_return(status: 200, body: File.read("./spec/fixtures/bib_19060447.json")
    )
  end

  describe "#is_research?" do
    it "should declare partner record as research" do
      expect(partner_record.is_research?).to eq(true)
    end

    it "should declare a bib with 0 items as research" do
      expect(zero_item_bib.is_research?).to eq(true)
    end

    it "should declare a bib with at least one research item as research" do
      expect(bib_with_research_item.is_research?).to eq(true)
    end

    it "should throw DeletedError for a deleted bib record" do
      expect { deleted_bib.is_research? }.to raise_error(DeletedError)
    end

    it "should declare a mixed bib as research" do
      expect(mixed_bib.is_research?).to eq(true)
    end
  end
end

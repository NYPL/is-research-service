describe 'app' do
  before(:each) do
    stub_request(:post, "#{ENV['NYPL_OAUTH_URL']}oauth/token")
      .to_return(status: 200, body: '{ "access_token": "fake-access-token" }')

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}items/sierra-nypl/37314241")
      .to_return(status: 200, body: File.read("./spec/fixtures/item_37314241.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_catalog_item_type.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_catalog_item_type.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_sierra_location.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_sierra_location.json"), headers: {})
  end

  it "should handle a valid api gateway event" do
    event = JSON.parse(File.read("./event.json")) # < Fill in API gateway event
    response = handle_event(event: event, context: '')

    lamba_resp = JSON.parse(response[:body])

    expect(response).to be_a(Object)
    expect(response[:statusCode]).to eq(200)
    expect(lamba_resp).to include("nypl_source", "id", "isResearch")
  end

  xit "should handle an invalid request with a 4**" do

  end

  xit "should respond with a 404 if requested id isn't found" do

  end
end

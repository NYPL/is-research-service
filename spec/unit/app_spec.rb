describe 'app' do
  before(:each) do
    stub_request(:post, "#{ENV['NYPL_OAUTH_URL']}oauth/token")
      .to_return(status: 200, body: '{ "access_token": "fake-access-token" }')

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}items/sierra-nypl/37314241")
      .to_return(status: 200, body: File.read("./spec/fixtures/item_37314241.json"))

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}items/sierra-nypl/F16398857")
      .to_return(status: 404, body: File.read("./spec/fixtures/sierra_404.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_catalog_item_type.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_catalog_item_type.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_sierra_location.json")
    .to_return(status: 200, body: File.read("./spec/fixtures/by_sierra_location.json"), headers: {})
  end

  it "should handle a valid api gateway event" do
    event = JSON.parse(File.read("./event.json"))
    response = handle_event(event: event, context: '')

    lamba_resp = JSON.parse(response[:body])

    expect(response).to be_a(Object)
    expect(response[:statusCode]).to eq(200)
    expect(lamba_resp.keys).to include("nyplSource", "id", "isResearch")
  end

  it "should respond with a 404 if requested item isn't found" do
    event = JSON.parse(File.read("./event_not_found.json"))
    response = handle_event(event: event, context: '')

    lamba_resp = JSON.parse(response[:body])

    expect(response).to be_a(Object)
    expect(response[:statusCode]).to eq(404)
    expect(lamba_resp["message"]).to eq("ParameterError: No record found")
  end
end

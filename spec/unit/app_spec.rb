 require 'webmock/rspec'

require_relative '../../app'

ENV['LOG_LEVEL'] ||= 'info'
ENV['APP_ENV'] = 'test'
ENV['PLATFORM_API_BASE_URL'] = 'https://example.com/api/v0.1/'
ENV['NYPL_OAUTH_ID'] = Base64.strict_encode64 'fake-client'
ENV['NYPL_OAUTH_SECRET'] = Base64.strict_encode64 'fake-secret'
ENV['NYPL_OAUTH_URL'] = 'https://isso.example.com/'
ENV['NYPL_CORE_S3_BASE_URL'] = 'https://example.com/'

describe 'app' do
  before(:each) do
    stub_request(:post, "#{ENV['NYPL_OAUTH_URL']}oauth/token")
      .to_return(status: 200, body: '{ "access_token": "fake-access-token" }')

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}items/sierra-nypl/10002559")
      .to_return(status: 200, body: File.read("spec/fixtures/item_10002559.json"))

    stub_request(:get,
      "#{ENV['PLATFORM_API_BASE_URL']}items/sierra-nypl/F16398857")
      .to_return(status: 404, body: File.read("spec/fixtures/sierra_404.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_catalog_item_type.json")
    .to_return(status: 200, body: File.read("spec/fixtures/by_catalog_item_type.json"))

    stub_request(:get, ENV['NYPL_CORE_S3_BASE_URL'] + "by_sierra_location.json")
    .to_return(status: 200, body: File.read("spec/fixtures/by_sierra_location.json"))
  end

  it "should handle a valid api gateway event" do
    event = JSON.parse(File.read("./events/event-item_is_research_true.json"))
    response = handle_event(event: event, context: '')

    lambda_resp = JSON.parse(response[:body])

    expect(response).to be_a(Object)
    expect(response[:statusCode]).to eq(200)
    expect(lambda_resp.keys).to include("nyplSource", "id", "isResearch")
  end

  it "should return swagger if requested path is docs/is-research" do
    event = JSON.parse(File.read("./events/event-swagger.json"))
    response = handle_event(event: event, context: '')

    lambda_resp = JSON.parse(response[:body])

    expect(response[:statusCode]).to eq(200)
    expect(lambda_resp).to be_a(Object)
    expect(lambda_resp["swagger"]).to eq('2.0')
    expect(lambda_resp["info"]["title"]).to eq('Is Research Service')
  end

  it "should respond with a 404 if requested item isn't found" do
    event = JSON.parse(File.read("./events/event-not_found.json"))
    response = handle_event(event: event, context: '')

    lambda_resp = JSON.parse(response[:body])

    expect(response).to be_a(Object)
    expect(response[:statusCode]).to eq(404)
    expect(lambda_resp["message"]).to eq("NotFoundError: Record not found")
  end
end

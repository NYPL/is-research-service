require 'json'
require 'test/unit'
require 'mocha/test_unit'

require_relative '../../app'

class IsResearchTest < Test::Unit::TestCase
  ENV['NYPL_OAUTH_ID'] = Base64.strict_encode64 'fake-client'
  ENV['NYPL_OAUTH_SECRET'] = Base64.strict_encode64 'fake-secret'

  def event
    File.read("./event.json")
  end

  def mock_response
    Object.new.tap do |mock|
      mock.expects(:code).returns(200)
      mock.expects(:body).returns('1.1.1.1')
    end
  end

  def expected_result
    {
      statusCode: 200,
      body: {
        is_research: true
      }.to_json
    }
  end

  def test_lambda_handler
    # HTTParty.expects(:get).with('http://checkip.amazonaws.com/').returns(mock_response)
    assert_equal(handle_event(event: event, context: ''), expected_result)
  end
end

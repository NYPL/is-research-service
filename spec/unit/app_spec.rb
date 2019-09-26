describe 'app' do
  before(:each) do
    # Set up necessary mocks...
  end

  xit "should handle a valid api gateway event" do
    const event = {} # < Fill in API gateway event
    response = handle_event(event: event, context: '')

    expect(response).to be_a(Object)
    # Expect more things about the response here
  end

  xit "should handle an invalid request with a 4**" do

  end
  
  xit "should respond with a 404 if requested id isn't found" do

  end
end

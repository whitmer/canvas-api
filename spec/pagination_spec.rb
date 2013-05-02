require "spec_helper"

describe "Pagination" do
  it "should return an array of results on a valid call" do
    token_api
    @api.generate_uri("/api/v1/bacon")
    stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json)
    req = @api.get_request("/api/v1/bacon")
    json = @api.retrieve_response(req)
    json.should be_is_a(Array)
  end
  
  it "should return a Canvas result set" do
    token_api
    @api.generate_uri("/api/v1/bacon")
    stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json)
    req = @api.get_request("/api/v1/bacon")
    json = @api.retrieve_response(req)
    json.should be_is_a(Canvas::ResultSet)
  end
  
  context "next_page!" do
    it "should correctly retrieve the next set of results" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json, :link => "<https://canvas.instructure.com/api/v1/bacon?page=2>; rel=\"next\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      req = @api.get_request("/api/v1/bacon")
      json = @api.retrieve_response(req)
      json.should be_is_a(Array)
      json.length.should == 1
      json.next_endpoint.should == "/api/v1/bacon?page=2"
      
      stub_request("/api/v1/bacon?page=2", :code => 200, :body => [{:bacon => true}].to_json)
      new_list = json.next_page!
      json.length.should == 2
      new_list.length.should == 1
      json.next_endpoint.should == nil
    end
    
    it "should correctly retrieve more than two pages" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json, :link => "<https://canvas.instructure.com/api/v1/bacon?page=2>; rel=\"next\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      req = @api.get_request("/api/v1/bacon")
      json = @api.retrieve_response(req)
      json.should be_is_a(Array)
      json.length.should == 1
      json.next_endpoint.should == "/api/v1/bacon?page=2"
      
      stub_request("/api/v1/bacon?page=2", :code => 200, :body => [{:bacon => true}].to_json, :link => "<https://canvas.instructure.com/api/v1/bacon?page=3>; rel=\"next\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      new_list = json.next_page!
      json.length.should == 2
      new_list.length.should == 1
      json.next_endpoint.should == "/api/v1/bacon?page=3"

      stub_request("/api/v1/bacon?page=3", :code => 200, :body => [{:bacon => true}].to_json, :link => "<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      new_list = json.next_page!
      json.length.should == 3
      new_list.length.should == 1
      json.next_endpoint.should == nil
    end
    
    it "should correctly handle when there are no more pages" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json, :link => "<https://canvas.instructure.com/api/v1/bacon?page=2>; rel=\"next\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      req = @api.get_request("/api/v1/bacon")
      json = @api.retrieve_response(req)
      json.should be_is_a(Array)
      json.length.should == 1
      json.next_endpoint.should == "/api/v1/bacon?page=2"
      
      stub_request("/api/v1/bacon?page=2", :code => 200, :body => [].to_json, :link => "<https://canvas.instructure.com/api/v1/bacon?page=3>; rel=\"next\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      new_list = json.next_page!
      json.length.should == 1
      new_list.length.should == 0
      json.next_endpoint.should == "/api/v1/bacon?page=3"

      stub_request("/api/v1/bacon?page=3", :code => 200, :body => [].to_json, :link => "<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=1&per_page=10>; rel=\"first\",<https://canvas.instructure.com/api/v1/courses/:id/discussion_topics.json?page=5&per_page=10>; rel=\"last\"")
      new_list = json.next_page!
      json.length.should == 1
      new_list.length.should == 0
      json.next_endpoint.should == nil
    end
  end
end

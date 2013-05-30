require "spec_helper"

describe "GET requests" do
  context "validate_call" do
    it "should raise on missing token" do
      client_api
      expect { @api.validate_call(nil) }.to raise_error(StandardError, "token required for api calls")
    end
    
    it "should raise on missing host" do
      token_api
      @api.host = nil
      expect { @api.validate_call(nil) }.to raise_error(StandardError, "missing host")
    end
    
    it "should raise on invalid endpoint" do
      token_api
      expect { @api.validate_call(nil) }.to raise_error(StandardError, "missing endpoint")
      expect { @api.validate_call("api/v1/bacon") }.to raise_error(StandardError, "missing leading slash on endpoint")
    end
    
    it "should raise on malformed endpoint URL" do
      token_api
      expect { @api.validate_call("/api/v1/A$#^B$^#$B^") }.to raise_error(StandardError, "invalid endpoint")
    end
  end
  
  context "generate_uri" do
    it "should correctly append the access token" do
      token_api
      @api.generate_uri("/api/v1/bacon").to_s.should == "http://canvas.example.com/api/v1/bacon?access_token=#{@api.token}"
    end
    
    it "should correctly append masquerading id if any set" do
      token_api
      @api.masquerade_as(123)
      @api.generate_uri("/api/v1/bacon?a=1").to_s.should == "http://canvas.example.com/api/v1/bacon?a=1&access_token=#{@api.token}&as_user_id=123"
    end
    
    it "should generate a valid http object" do
      token_api
      @api.instance_variable_get('@http').should == nil
      @api.generate_uri("/api/v1/bacon")
      http = @api.instance_variable_get('@http')
      http.should_not == nil
    end
    
    it "should correctly detect ssl" do
      token_api
      @api.instance_variable_get('@http').should == nil
      @api.generate_uri("/api/v1/bacon")
      http = @api.instance_variable_get('@http')
      http.should_not == nil
      http.use_ssl?.should == false
      
      @api.host = "https://canvas.example.com"
      @api.generate_uri("/api/v1/bacon")
      http = @api.instance_variable_get('@http')
      http.should_not == nil
      http.use_ssl?.should == true
    end
  end
  
  context "retrieve_response" do
    it "should raise on redirect" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 302, :location => "http://www.example.com")
      req = @api.get_request("/api/v1/bacon")
      expect { @api.retrieve_response(req) }.to raise_error(Canvas::ApiError, "unexpected redirect to http://www.example.com")
    end
    
    it "should raise on non-200 response" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 400, :body => {}.to_json)
      req = @api.get_request("/api/v1/bacon")
      expect { @api.retrieve_response(req) }.to raise_error(Canvas::ApiError, " unexpected error")
    end
    
    it "should parse error messages" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 400, :body => {:message => "bad message", :status => "invalid"}.to_json)
      req = @api.get_request("/api/v1/bacon")
      expect { @api.retrieve_response(req) }.to raise_error(Canvas::ApiError, "invalid bad message")
    end
    
    it "should raise on non-JSON response" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 400, :body => "<xml/>")
      req = @api.get_request("/api/v1/bacon")
      expect { @api.retrieve_response(req) }.to raise_error(Canvas::ApiError, "invalid JSON")
    end
    
    it "should return JSON on valid response" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 200, :body => {:bacon => true}.to_json)
      req = @api.get_request("/api/v1/bacon")
      json = @api.retrieve_response(req)
      json['bacon'].should == true
    end
    
    it "should return ResultSet on valid array response" do
      token_api
      @api.generate_uri("/api/v1/bacon")
      stub_request("/api/v1/bacon", :code => 200, :body => [{:bacon => true}].to_json)
      req = @api.get_request("/api/v1/bacon")
      json = @api.retrieve_response(req)
      json[0]['bacon'].should == true
      json.next_endpoint.should == nil
    end
    
    it "should append query parameters if specified" do
      token_api
      @api.generate_uri("/api/v1/bacon?c=x", {'a' => '1', 'b' => '2'}).request_uri.should == "/api/v1/bacon?c=x&access_token=#{@api.token}&a=1&b=2"
      @api.should_receive(:generate_uri).with('/api/v1/bob', {'a' => 1})
      @api.should_receive(:get_request).and_raise("stop here")
      expect { @api.get("/api/v1/bob", {'a' => 1}) }.to raise_error("stop here")
    end
    
    it "should handle numerical query parameters" do
      token_api
      @api.generate_uri("/api/v1/bacon", {'a' => 1, 'b' => 2, 'c' => @api}).request_uri.should == "/api/v1/bacon?access_token=#{@api.token}&a=1&b=2&c=#{CGI.escape(@api.to_s)}"
    end
    
    it "should handle array query parameters, with or without the []" do
      token_api
      @api.generate_uri("/api/v1/bacon", {'a[]' => 1, 'b' => [2,3]}).request_uri.should == "/api/v1/bacon?access_token=#{@api.token}&a%5B%5D=1&b%5B%5D=2&b%5B%5D=3"
      @api.generate_uri("/api/v1/bacon", [['a[]', 1], ['b', [2,3]]]).request_uri.should == "/api/v1/bacon?access_token=#{@api.token}&a%5B%5D=1&b%5B%5D=2&b%5B%5D=3"
    end
    
    it "should not fail on no query parameters argument" do
      token_api
      @api.generate_uri("/api/v1/bacon").request_uri.should == "/api/v1/bacon?access_token=#{@api.token}"
    end
  end
end

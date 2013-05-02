require "spec_helper"

describe "OAuth" do
  context "oauth_url" do
    # including login_url
    it "should fail without a client_id and secret" do
      token_api
      expect { @api.oauth_url(nil) }.to raise_error(StandardError, "client_id required for oauth flow")
      @api.client_id = "bob"
      expect { @api.oauth_url(nil) }.to raise_error(StandardError, "secret required for oauth flow")
    end
    
    it "should fail gracefully on an invalid callback_url" do
      client_api
      expect { @api.oauth_url(nil) }.to raise_error(StandardError, "callback_url required")
      expect { @api.oauth_url("(*&^%$#") }.to raise_error(StandardError, "invalid callback_url")
    end
    
    it "should craft valie urls" do
      client_api
      @api.oauth_url("http://www.example.com", nil).should == "http://canvas.example.com/login/oauth2/auth?client_id=#{@api.client_id}&response_type=code&redirect_uri=http%3A%2F%2Fwww.example.com"
      @api.oauth_url("http://www.example.com/return?id=1234", "cool/scope").should == "http://canvas.example.com/login/oauth2/auth?client_id=#{@api.client_id}&response_type=code&redirect_uri=http%3A%2F%2Fwww.example.com%2Freturn%3Fid%3D1234&scopes=cool%2Fscope"
      @api.login_url("http://www.example.com").should == "http://canvas.example.com/login/oauth2/auth?client_id=#{@api.client_id}&response_type=code&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=%2Fauth%2Fuserinfo"
    end
  end
  
  context "retrieve_access_token" do
    it "should fail without a client_id and secret" do
      token_api
      expect { @api.retrieve_access_token(nil, nil) }.to raise_error(StandardError, 'client_id required for oauth flow')
    end
    
    it "should fail without a code" do
      client_api
      expect { @api.retrieve_access_token(nil, nil) }.to raise_error(StandardError, 'code required')
    end
    
    it "should fail on an invalid callback_url" do
      client_api
      expect { @api.retrieve_access_token("abc", nil) }.to raise_error(StandardError, 'callback_url required')
      expect { @api.retrieve_access_token("abc", "(*&^%$#") }.to raise_error(StandardError, 'invalid callback_url')
    end
    
    it "should successfully retrieve an access token" do
      client_api
      @api.should_receive(:post).and_return({'access_token' => 'asdf'})
      res = @api.retrieve_access_token("abc", "http://www.example.com")
      res.should == {'access_token' => 'asdf'}
      @api.token.should == 'asdf'
    end
  end
  
  context "logout" do
    it "should fail without a token" do
      client_api
      expect { @api.logout }.to raise_error(StandardError, "token required for api calls")
    end
    
    it "should return success" do
      token_api
      @api.should_receive(:delete).and_return({'logged_out' => true})
      @api.logout.should == true

      @api.should_receive(:delete).and_return({'logged_out' => false})
      @api.logout.should == false

      @api.should_receive(:delete).and_return({})
      @api.logout.should == false
    end
  end
end

#     def retrieve_access_token(code, callback_url)
#       raise "client_id required for oauth flow" unless @client_id
#       raise "secret required for oauth flow" unless @secret
#       post("/login/oauth2/token", :client_id => @client_id, :redirect_uri => callback_url, :client_secret => @secret, :code => code)
#     end
#   
#     def logout
#       delete("/login/oauth2/token")
#     end
#   

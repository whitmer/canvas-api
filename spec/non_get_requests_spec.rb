require "spec_helper"

describe "Non-GET Requests" do
  it "should raise on missing token" do
    client_api
    expect { @api.post(nil) }.to raise_error(StandardError, "token required for api calls")
  end
  
  it "should raise on missing host" do
    token_api
    @api.host = nil
    expect { @api.delete(nil) }.to raise_error(StandardError, "missing host")
  end
  
  it "should raise on invalid endpoint" do
    token_api
    expect { @api.put(nil) }.to raise_error(StandardError, "missing endpoint")
    expect { @api.delete("api/v1/bacon") }.to raise_error(StandardError, "missing leading slash on endpoint")
  end
  
  it "should raise on malformed endpoint URL" do
    token_api
    expect { @api.put("/api/v1/A$#^B$^#$B^") }.to raise_error(StandardError, "invalid endpoint")
  end
  
  context "clean_params" do
  
    it "should fix hashed parameters list" do
      token_api
      @api.clean_params({}).should == []
      @api.clean_params({'a' => 1, 'b' => 2}).should == [['a', '1'],['b','2']]
      @api.clean_params({'a' => {'a' => 1, 'b' => 3}, 'b' => 2}).should == [["a[a]", "1"], ["a[b]", "3"], ["b", "2"]]
      
      a = @api.clean_params({'user[name]' => 'Dixon Wilson', 'user[short_name]' => 'Dixon'})
      b = @api.clean_params({'user' => {'name' => 'Dixon Wilson', 'short_name' => 'Dixon'}})
      a.should == b
      c = @api.clean_params([['user[name]', 'Dixon Wilson'],['user[short_name]', 'Dixon']])
      a.should == c
      b.should == c
    end
  
    it "should support arbitrary levels of nesting on hashed parameters list" do
      token_api
      @api.clean_params({'a' => 1, 'b' => 2}).should == [['a', '1'],['b','2']]
      @api.clean_params({'a' => {'b' => {'c' => {'d' => 1}}}}).should == [["a[b][c][d]", "1"]]
    end
  
    it "should fail on arrays for hashed parameters list" do
      token_api
      expect { @api.clean_params({'a' => [1,2]}) }.to raise_error("No support for nested array parameters currently")
    end
  end
end

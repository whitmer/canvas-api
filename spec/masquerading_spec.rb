require "spec_helper"

describe "Masquerading" do
  it "should remember masquerading id" do
    token_api
    @api.masquerade_as(2)
    @api.instance_variable_get('@as_user_id').should == '2'
  end
  
  it "should use masquerading id when set" do
    token_api
    @api.masquerade_as(2)
    url_called(@api, :get, "/api/v1/bacon").should match(/as_user_id=2/)
    url_called(@api, :get, "/api/v1/cheetos").should match(/as_user_id=2/)
  end
  
  it "should stop using masquerading id when cleared" do
    token_api
    @api.masquerade_as(2)
    url_called(@api, :get, "/api/v1/bacon").should match(/as_user_id=2/)
    @api.stop_masquerading
    url_called(@api, :get, "/api/v1/cheetos").should_not match(/as_user_id/)
  end
  
  it "should ignore nil masquerading id" do
    token_api
    @api.masquerade_as(nil)
    url_called(@api, :get, "/api/v1/bacon").should_not match(/as_user_id/)
  end
end
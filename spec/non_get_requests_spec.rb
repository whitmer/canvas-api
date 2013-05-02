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
end
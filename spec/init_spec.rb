require "spec_helper"

describe "Init" do
  it "should error if no host provided" do
    expect { Canvas::API.new }.to raise_error(RuntimeError, "host required")
    expect { Canvas::API.new(:host => nil) }.to raise_error(RuntimeError, "host required")
  end
  
  it "should error if invalid host provided" do
    expect { Canvas::API.new(:host => "canvas.example.com") }.to raise_error(RuntimeError, "invalid host, protocol required")
    expect { Canvas::API.new(:host => "ftp://canvas.example.com") }.to raise_error(RuntimeError, "invalid host, protocol required")
    expect { Canvas::API.new(:host => "http://canvas.example.com/") }.to raise_error(RuntimeError, "invalid host")
    expect { Canvas::API.new(:host => "http://canvas.example.com/") }.to raise_error(RuntimeError, "invalid host")
  end

  it "should error if no token or client id provided" do
    expect { Canvas::API.new(:host => "http://canvas.example.com") }.to raise_error(RuntimeError, "token or client_id required")
    expect { Canvas::API.new(:host => "http://canvas.example.com", :token => nil) }.to raise_error(RuntimeError, "token or client_id required")
  end
  
  it "should accept valid configurations" do
    expect { Canvas::API.new(:host => "http://canvas.example.com", :token => "abc") }.to_not raise_error
    expect { Canvas::API.new(:host => "http://canvas.api.of.coolness.example.com", :client_id => 123) }.to raise_error(RuntimeError, "secret required for client_id configuration")
    expect { Canvas::API.new(:host => "http://canvas.api.of.coolness.example.com", :client_id => 123, :secret => "abc") }.to_not raise_error
  end
  
end
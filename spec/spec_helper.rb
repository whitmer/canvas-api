lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
SLEEP_TIME = 0.1

require 'canvas-api'
require 'rspec'
require 'net/http'
require 'ostruct'

def token_api
  @api = Canvas::API.new(:host => "http://canvas.example.com", :token => "abc#{rand(999)}")
end

def client_api
  @api = Canvas::API.new(:host => "http://canvas.example.com", :client_id => rand(99999), :secret => rand(99999).to_s)
end

def file_handle
  File.open(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'canvas-api.rb')), 'r')
end

def url_called(api, *args)
  @api.should_receive(:retrieve_response).and_return(nil)
  @api.send(*args)
  @api.instance_variable_get('@uri').to_s
end

def stub_request(endpoint, args)
  @request ||= Typhoeus::Request.new(endpoint)
  @response ||= OpenStruct.new
  @response.code = (args[:code] || 200).to_s
  @response.body = args[:body].to_s
  @response.headers = {
    'Location' => args[:location],
    'Link' => args[:link]
  }

  Typhoeus::Request.any_instance.stub(:run).and_return(@response)
  @api.should_receive(:get_request).and_return(@request)
  @request
end

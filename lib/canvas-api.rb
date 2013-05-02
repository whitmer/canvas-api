require 'uri'
require 'cgi'
require 'net/http'
require 'json'

module Canvas
  class API
    def initialize(args={}) 
      @host = args[:host] && args[:host].to_s
      @token = args[:token] && args[:token].to_s
      @client_id = args[:client_id] && args[:client_id].to_s
      @secret = args[:secret] && args[:secret].to_s
      raise "host required" unless @host
      raise "invalid host, protocol required" unless @host.match(/^http/)
      raise "invalid host" unless @host.match(/^https?:\/\/[^\/]+$/)
      raise "token or client_id required" if !@token && !@client_id
      raise "secret required for client_id configuration" if @client_id && !@secret
    end
  
    attr_accessor :host
    attr_accessor :token
    attr_accessor :client_id
  
    def masquerade_as(user_id)
      @as_user_id = user_id && user_id.to_s
    end
  
    def stop_masquerading
      @as_user_id = nil
    end
  
    def self.encode_id(prefix, id)
      return nil unless prefix && id
      "hex:#{prefix}:" + id.to_s.unpack("H*")[0]
    end
    
    def encode_id(prefix, id)
      Canvas::API.encode_id(prefix, id)
    end
  
    def oauth_url(callback_url, scopes="")
      raise "client_id required for oauth flow" unless @client_id
      raise "secret required for oauth flow" unless @secret
      raise "callback_url required" unless callback_url
      raise "invalid callback_url" unless (URI.parse(callback_url) rescue nil)
      scopes ||= ""
      scopes = scopes.length > 0 ? "&scopes=#{CGI.escape(scopes)}" : ""
      "#{@host}/login/oauth2/auth?client_id=#{@client_id}&response_type=code&redirect_uri=#{CGI.escape(callback_url)}#{scopes}"
    end
  
    def login_url(callback_url)
      oauth_url(callback_url, "/auth/userinfo")
    end
  
    def retrieve_access_token(code, callback_url)
      raise "client_id required for oauth flow" unless @client_id
      raise "secret required for oauth flow" unless @secret
      raise "code required" unless code
      raise "callback_url required" unless callback_url
      raise "invalid callback_url" unless (URI.parse(callback_url) rescue nil)
      @token = "ignore"
      res = post("/login/oauth2/token", :client_id => @client_id, :redirect_uri => callback_url, :client_secret => @secret, :code => code)
      if res['access_token']
        @token = res['access_token']
      end
      res
    end
  
    def logout
      !!delete("/login/oauth2/token")['logged_out']
    end
  
    def validate_call(endpoint)
      raise "token required for api calls" unless @token
      raise "missing host" unless @host
      raise "missing endpoint" unless endpoint
      raise "missing leading slash on endpoint" unless endpoint.match(/^\//)
      raise "invalid endpoint" unless endpoint.match(/^\/api\/v\d+\//) unless @token == 'ignore'
      raise "invalid endpoint" unless (URI.parse(endpoint) rescue nil)
    end
  
    def generate_uri(endpoint)
      validate_call(endpoint)
      unless @token == "ignore"
        endpoint += (endpoint.match(/\?/) ? "&" : "?") + "access_token=" + @token
        endpoint += "&as_user_id=" + @as_user_id.to_s if @as_user_id
      end
      @uri = URI.parse(@host + endpoint)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.use_ssl = @uri.scheme == 'https'
      @uri
    end
  
    def retrieve_response(request)
      request['User-Agent'] = "CanvasAPI Ruby"
      begin
        response = @http.request(request)
      rescue Timeout::Error => e
        raise ApiError.new("request timed out")
      end
      raise ApiError.new("unexpected redirect to #{response.location}") if response.code.to_s.match(/3\d\d/)
      json = JSON.parse(response.body) rescue {'error' => 'invalid JSON'}
      if !json.is_a?(Array)
        raise ApiError.new(json['error']) if json['error']
        if !response.code.to_s.match(/2\d\d/)
          json['message'] ||= "unexpected error"
          raise ApiError.new("#{json['status']} #{json['message']}") 
        end
      else
        json = ResultSet.new(self, json)
        if response['link']
          json.link = response['link']
          json.next_endpoint = response['link'].split(/,/).detect{|rel| rel.match(/rel="next"/) }.split(/;/).first.strip[1..-2].sub(/https?:\/\/[^\/]+/, '') rescue nil
        end
      end
      json
    end
    
    # Semi-hack so I can write better specs
    def get_request(endpoint)
      Net::HTTP::Get.new(@uri.request_uri)
    end
  
    def get(endpoint)
      generate_uri(endpoint)
      request = get_request(endpoint)
      retrieve_response(request)
    end
  
    def delete(endpoint)
      generate_uri(endpoint)
      request = Net::HTTP::Delete.new(@uri.request_uri)
      retrieve_response(request)
    end
  
    def put(endpoint, params={})
      generate_uri(endpoint)
      request = Net::HTTP::Put.new(@uri.request_uri)
      request.set_form_data(params)
      retrieve_response(request)
    end
  
    def post(endpoint, params={})
      generate_uri(endpoint)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(params)
      retrieve_response(request)
    end
  
    def upload_file_from_local
      # TODO
    end
  
    def upload_file_from_url
      # TODO
    end
  end

  class ApiError < StandardError
  end

  class ResultSet < Array
    def initialize(api, arr)
      @api = api
      super(arr)
    end
    attr_accessor :next_endpoint
    attr_accessor :link
    
    def more?
      !!next_endpoint
    end
    
    def next_page!
      ResultSet.new(@api, []) unless next_endpoint
      more = @api.get(next_endpoint)
      concat(more)
      @next_endpoint = more.next_endpoint
      @link = more.link
      more
    end
  end
end
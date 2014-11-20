require "spec_helper"

describe "File Uploads" do
  context "from local" do
    it "should fail on invalid file object" do
      token_api
      expect { @api.upload_file_from_local("/api/v1/users/self/files", nil) }.to raise_error("Missing File object")
    end
    
    it "should make a valid setup call" do
      token_api
      file = file_handle
      args = {
        :size => file.size,
        :name => 'canvas-api.rb',
        :content_type => 'application/octet-stream',
        :on_duplicate => nil
      }
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({})
      expect { @api.upload_file_from_local("/api/v1/users/self/files", file) }.to raise_error("Unexpected error: no upload URL returned")
    end
    
    it "should call multipart_upload correctly" do
      token_api
      file = file_handle
      args = {
        :size => file.size,
        :name => 'canvas-api.rb',
        :content_type => 'application/octet-stream',
        :on_duplicate => nil
      }
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({'upload_url' => 'http://www.bacon.com', 'upload_params' => {'a' => 1, 'b' => 2}})
      @api.should_receive(:multipart_upload).and_raise("stop at multipart") #return("http://www.return.url/api/v1/success")
      expect { @api.upload_file_from_local("/api/v1/users/self/files", file) }.to raise_error("stop at multipart")
    end
    
    context "multipart_upload" do
      it "should error on missing status URL return" do
        token_api
        file = file_handle
        Typhoeus::Request.any_instance.should_receive(:run).and_return(OpenStruct.new({'headers' => {}, 'body' => 'nothing good here'}))
        expect { 
          @api.multipart_upload("http://www.example.com/", {'a' => 1, 'b' => 2}, {:content_type => 'application/octet-stream', :name => 'file'}, file)
        }.to raise_error(Canvas::ApiError, "Unexpected error: nothing good here")
      end
      
      it "should upload the parameters in the correct order (file last)" do
        path_to_lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
        token_api
        file = file_handle
        Typhoeus::Request.any_instance.should_receive(:run).and_return(OpenStruct.new({'headers' => {'Location' => 'http://www.new_status.url/api/v1/success'}}))
        res = @api.multipart_upload("http://www.example.com/", {'a' => 1, 'b' => 2}, {:content_type => 'application/octet-stream', :name => 'file'}, file)
        res.should == 'http://www.new_status.url/api/v1/success'
        req = @api.instance_variable_get('@multi_request')
        req.encoded_body.split(/&/)[-1].should == "file=canvas-api.rb=application/octet-stream=#{path_to_lib}/canvas-api.rb"
      end
    end
    
    it "should call the final status URL after upload" do
      token_api
      file = file_handle
      args = {
        :size => file.size,
        :name => 'canvas-api.rb',
        :content_type => 'application/octet-stream',
        :on_duplicate => nil
      }
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({'upload_url' => 'http://www.bacon.com', 'upload_params' => {'a' => 1, 'b' => 2}})
      @api.should_receive(:multipart_upload).and_return("http://www.return.url/api/v1/success")
      @api.should_receive(:get).with("/api/v1/success").and_return({'success' => true})
      res = @api.upload_file_from_local("/api/v1/users/self/files", file)
      res.should == {'success' => true}
    end
  end
  
  context "from URL" do
    it "should fail on missing values" do
      token_api
      expect { @api.upload_file_from_url("/api/v1/users/self/files", {}) }.to raise_error("Missing value: url")
      expect { @api.upload_file_from_url("/api/v1/users/self/files", :url => "http://www.example.com") }.to raise_error("Missing value: name")
      expect { @api.upload_file_from_url("/api/v1/users/self/files", :url => "http://www.example.com", :name => "file.html") }.to raise_error("Missing value: size")
    end
    
    it "should retrieve the status PATH (not URL) on valid setup step" do
      token_api
      args = {:url => "http://www.example.com", :name => "file.html", :size => 10}
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({'status_url' => 'http://www.bob.com/bob'})
      path = @api.upload_file_from_url("/api/v1/users/self/files", args.merge(:asynch => true))
      path.should == '/bob'
    end
    
    it "should raise an error on problems with the setup step" do
      token_api
      args = {:url => "http://www.example.com", :name => "file.html", :size => 10}
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({})
      expect { @api.upload_file_from_url("/api/v1/users/self/files", args.merge(:asynch => true)) }.to raise_error(Canvas::ApiError, "Unexpected error: no status URL returned")
    end
    
    it "should repeatedly call the status PATH on non-asynch" do
      token_api
      args = {:url => "http://www.example.com", :name => "file.html", :size => 10}
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({'status_url' => 'http://www.bob.com/bob'})
      @api.should_receive(:get).with("/bob").and_return({'upload_status' => 'pending', 'status_path' => '/bob2'})
      @api.should_receive(:get).with("/bob2").and_return({'upload_status' => 'pending', 'status_path' => '/bob3'})
      @api.should_receive(:get).with("/bob3").and_return({'upload_status' => 'success', 'attachment' => {'id' => 2}})
      attachment = @api.upload_file_from_url("/api/v1/users/self/files", args)
      attachment['id'].should == 2
    end

    it "should raise an error on an errored non-asynch call" do
      token_api
      args = {:url => "http://www.example.com", :name => "file.html", :size => 10}
      @api.should_receive(:post).with("/api/v1/users/self/files", args).and_return({'status_url' => 'http://www.bob.com/bob'})
      @api.should_receive(:get).with("/bob").and_return({'upload_status' => 'errored', 'message' => 'bad robot'})
      expect { @api.upload_file_from_url("/api/v1/users/self/files", args) }.to raise_error(Canvas::ApiError, "bad robot")
    end
  end
end

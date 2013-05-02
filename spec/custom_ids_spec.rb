require "spec_helper"

describe "Custom IDs" do
  it "should hex encode values correctly" do
    Canvas::API.encode_id('sis_course_id', '12344').should == 'hex:sis_course_id:3132333434'
    Canvas::API.encode_id('sis_user_id', 8900).should == 'hex:sis_user_id:38393030'
    Canvas::API.encode_id('sis_course_id', 'A)*#$B^)M)_@$*^B$_V@_#%*@#_').should == 'hex:sis_course_id:41292a2324425e294d295f40242a5e42245f56405f23252a40235f'
  end
  
  it "should fail gracefully on bad inputs" do
    Canvas::API.encode_id(nil, nil).should == nil
    Canvas::API.encode_id('sis_course_id', nil).should == nil
    Canvas::API.encode_id(nil, '12345').should == nil
  end
end
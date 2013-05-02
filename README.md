# Canvas API

This ruby library is to make it easier to use the
[Canvas API](http://api.instructure.com).

## Installation
This is packaged as the `canvas-api` rubygem, so you can just add the dependency to
your Gemfile or install the gem on your system:

    gem install canvas-api

To require the library in your project:

    require 'canvas-api'

## Usage

### OAuth Dance

Before you can make API calls you need an access token on behalf of the current user.
In order to get an access token you'll need to do the OAuth dance (and for that you'll
need a client_id and secret. Talk to the Canvas admin about getting these values):

```ruby
canvas = Canvas::API.new(:host => "https://canvas.example.com", :client_id => 123, :secret => "abcdef")
url = canvas.oauth_url("https://my.site/oauth_success")
# => "https://canvas.example.com/login/oauth2/auth?client_id=123&response_type=code&redirect_uri=http%3A%2F%2Fmy.site%2Foauth_success
redirect to(url)
```

And then when the browser redirects to oauth_success:

```ruby
canvas = Canvas::API.new(:host => "https://canvas.example.com", :client_id => 123, :secret => "abcdef")
code = params['code']
canvas.retrieve_access_token(code, 'https://my.site/oauth_success') # this callback_url must match the one provided in the first step
# => {access_token: "qwert"}
```
### General API Calls

Once you've got an access token for a user you should save it (securely!) for future use. To use the API call:

```ruby
canvas = Canvas::API.new(:host => "https://canvas.example.com", :token => "qwert")
canvas.get("/api/v1/users/self/profile")
# => {id: 90210, name: "Annie Wilson", ... }
```

### Pagination

API endpoints that return lists are often paginated, meaning they will only return the first X results
(where X depends on the endpoint and, possibly, the per_page parameter you optionally set). To get more
results you'll need to make additional API calls:

```ruby
canvas = Canvas::API.new(:host => "https://canvas.example.com", :token => "qwert")
list = canvas.get("/api/v1/calendar_events?all_events=true")
list.length
# => 50
list.more?
# => true (if there's another page of results)
list.next_page!
# => [...] (returns the next page of results)
list.length
# => 100 (also concatenates the results on to the previous list, if that's more convenient)
list.next_page!
# => [...]
list.length
# => 150
```

### Additional Utilities

There are also some helper methods that can make some of the other tricky parts of the Canvas API a little more approachable.

#### File Uploads

TODO...

#### SIS ID Encoding

In addition to regular IDs, Canvas supports [SIS IDs](https://canvas.instructure.com/doc/api/file.object_ids.html) defined
by other systems. Sometimes these IDs contain non-standard characters, which can cause problems when
trying to use them via the API. In those cases you can do the following:

```ruby
sis_course_id = canvas.encode_id("sis_course_id", "r#-789")
# => "hex:sis_course_id:72232d373839"
canvas.get("/api/v1/courses/#{sis_course_id}/enrollments")
# => [...]
```


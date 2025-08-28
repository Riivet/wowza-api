# Wowza::Api

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/wowza/api`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wowza-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wowza-api

## Usage

Configure the api keys

```ruby
Wowza::Api.configure do |config|
  config.jwt = ENV['WOWZA_JWT']

  # specify a logger to log requests and responses
  config.logger = Logger.new('/path/to/file')

  # logs the api path that matches the regex
  config.logger_filter = /transcoder|stream_target/ 

  # if you want to specify which verbs get logged for example:
  # only PUT requests which match the regular expression:
  config.logger_filter = {
    put: /transcoder\/.*/ # logs any time a transcoder is updated
  }
end
```

```ruby
transcoder = Wowza::Api::Transcoder.retrieve('xyz')
properties = transcoder.properties
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wowza-api.

Documentation:

https://developer.wowza.com/docs/wowza-video/api/video/current/tag/transcoders/

# Roy

Reason for _roy_:

We run [Resque](https://github.com/resque/resque) workers hosted on AWS using auto scaling groups.  In order to ensure workers are always running we use the super awesome [God](www.godrb.com) gem.

Our issue is when scaling-in we need to inform the resque workers to gracefully shutdown .i.e:

* Finish the current job
* Stop polling for new jobs
* Terminate the process

While we do make use of Resque's remote shutdown - God does what God does best and restarts the process.  One solution would be to implement remote pause in Resque - we required additional management of our remote nodes during termination.

More to follow.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install roy

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/aleak/roy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

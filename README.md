# Dvdvrconv [![Gem Version](https://badge.fury.io/rb/dvdvrconv.svg)](https://badge.fury.io/rb/dvdvrconv)

  
Dvdvrconv extracts the `vob` file from the `vro` file on the dvd-vr format disc.
Dvdvrconv is also a wrapper for [pixelb/dvd-vr](https://github.com/pixelb/dvd-vr/).

For Windows users, I attached `dvd-vr.exe` for cygwin environment.

## dependent libraries

*  [pixelb/dvd-vr](https://github.com/pixelb/dvd-vr/)
*  FFmpeg

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dvdvrconv'
```

And then execute:
```ruby
$ bundle install
```
Or install it yourself as:
```ruby
$ gem install dvdvrconv
```


## Usage

```
>dvdvrconv -h
Usage: dvdvrconv [options]
    -v, --version                    Show version
    -i, --info                       Show file information
        --config=FILE                Use YAML format FILE.
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

pixelb/dvd-vr is licensed under the GNU General Public License v2.0
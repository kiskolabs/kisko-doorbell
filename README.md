# Kisko::Doorbell

Listen for the doorbell signal using [rtl_433](https://github.com/merbanan/rtl_433) and an [RTL-SDR](https://www.rtl-sdr.com) receiver and notify Slack when the right doorbell rings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kisko-doorbell'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kisko-doorbell

## Usage

```
Usage: kisko-doorbell [options]
    -d, --doorbell-id=ID             Doorbell ID (decimal, not hex)
    -c, --slack-channel=#CHANNEL     Slack channel
    -t, --slack-token=TOKEN          Slack API token
    -T, --[no-]test                  Run in test mode instead of using the receiver
    -h, --help                       Show this message
    -v, --version                    Show version
```

## Sample systemd service

```ini
[Unit]
Description=Kisko Doorbell

[Service]
SyslogIdentifier=kisko-doorbell
User=root
Environment="HONEYBADGER_API_KEY=def456" "HONEYBADGER_ENV=production"
ExecStart=/usr/local/bin/kisko-doorbell --slack-token="abcde12345" --slack-channel="#general" --doorbell-id=123456
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matiaskorhonen/kisko-doorbell.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Kisko::Doorbell

Listen for the doorbell signal using [rtl_433](https://github.com/merbanan/rtl_433) and an [RTL-SDR](https://www.rtl-sdr.com) receiver and notify Slack when the right doorbell rings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kisko-doorbell'
```

Then run:

```shell
bundle
```

Or install it yourself as:

```shell
gem install kisko-doorbell
```

## Usage

```text
Usage: kisko-doorbell [options]
    -d, --doorbell-id=ID             Doorbell ID (decimal, not hex)
    -c, --slack-channel=#CHANNEL     Slack channel
    -t, --slack-token=TOKEN          Slack API token
        --slack-token-file=PATH      Read the Slack API token from a file
    -T, --[no-]test                  Run in test mode instead of using the receiver
    -h, --help                       Show this message
    -v, --version                    Show version
```

## Sample systemd service

Store the Slack token outside the unit and restrict it to the service account:

```shell
sudo install -d -m 700 /etc/kisko-doorbell
sudoedit /etc/kisko-doorbell/slack-token
sudo chmod 600 /etc/kisko-doorbell/slack-token
```

```ini
[Unit]
Description=Kisko Doorbell

[Service]
SyslogIdentifier=kisko-doorbell
User=root
Environment="HONEYBADGER_ENV=production"
Environment="KISKO_DOORBELL_SLACK_TOKEN_FILE=/etc/kisko-doorbell/slack-token"
ExecStart=/usr/local/bin/kisko-doorbell "--slack-channel=#general" --doorbell-id=2810647
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Maintaining and releasing

The source repository is [kiskolabs/kisko-doorbell](https://github.com/kiskolabs/kisko-doorbell). Use it for bug fixes and releases.

The release workflow is:

1. Make and validate the changes.
2. Update `lib/kisko/doorbell/version.rb` and `CHANGELOG.md`.
3. Commit the release and push `master` without creating the version tag.
4. Run the release script from the workstation.
5. Ring the installed doorbell and confirm the live result when prompted.

### Automated release

Prepare and push the release commit. The script reads the version from `lib/kisko/doorbell/version.rb`.

```shell
git add --all
git commit -m "Release 0.5.1"
git push origin master

usr/bin/release.rb --host pi@doorbell --sudo
```

The script requires a clean `master` whose commit is already on `origin/master`. It runs the Ruby, Trunk, and Pray checks; verifies the restricted Slack token configuration; checks out the exact commit on the Raspberry Pi; builds and installs the gem; restarts and verifies the service; and requests a live button test. Only after that confirmation does it create and push the annotated version tag.

Progress is stored under `tmp/releases/`. Run the same command after a failure to resume at the first incomplete step. Use `--restart-progress` to rerun every step. The `--sudo` option is required for the `pi` account and expects passwordless sudo for protected preflight checks, gem installation, and systemd operations.

This repository is not configured for public gem publication. Do not run `bundle exec rake release` or `gem push` unless the intended gem server has been configured and publication was explicitly requested.

### First Raspberry Pi setup

```shell
sudo apt update
sudo apt install -y git ruby ruby-dev build-essential
git clone https://github.com/kiskolabs/kisko-doorbell.git
cd kisko-doorbell
```

The deployed Pi currently uses Ruby 2.7. The development lockfile uses Bundler 2.6.9 and Ruby 3.4, so do not run `bundle install` from that lockfile on the deployed host. Building the gem itself does not require the development bundle.

### Manual fallback

Use these commands only when the release script cannot be run. Replace the example commit and version with the prepared release.

```shell
cd /home/pi/kisko-doorbell
git fetch origin master
git checkout --detach <release-commit>
gem build kisko-doorbell.gemspec
sudo ruby -rrubygems/package - ./kisko-doorbell-0.5.1.gem <<'RUBY'
package = Gem::Package.new(ARGV.fetch(0))
package.spec.runtime_dependencies.each do |dependency|
  installed = system(
    "gem", "install", dependency.name,
    "--version", dependency.requirement.to_s,
    "--conservative", "--no-document", "--verbose"
  )
  exit 1 unless installed
end
RUBY
sudo gem install --local --conservative --no-document --verbose ./kisko-doorbell-0.5.1.gem
/usr/local/bin/kisko-doorbell --version
```

The reported version must match the prepared release version.

Install the declared runtime dependencies first, then use `--local` for the unpublished doorbell gem. This avoids RubyGems downloading and processing its full legacy index after the local package name returns 404. If an earlier installation stopped while resolving dependencies, retry with:

```shell
sudo apt install -y ruby-dev build-essential
sudo gem install bigdecimal -v '~> 3.1' --conservative --no-document --verbose
sudo gem install --local --conservative --no-document --verbose /tmp/kisko-doorbell-0.5.1.gem
```

Create the restricted Slack token file once, or replace its contents when rotating the credential:

```shell
sudo install -d -m 700 -o root -g root /etc/kisko-doorbell
sudoedit /etc/kisko-doorbell/slack-token
sudo chmod 600 /etc/kisko-doorbell/slack-token
sudo systemctl edit --full kisko-doorbell
```

Rotate the previously exposed Slack credential before writing the replacement to this file. In the unit editor, use `KISKO_DOORBELL_SLACK_TOKEN_FILE` as shown in the sample unit above and remove `--slack-token`. Then reload, restart, and inspect it:

```shell
sudo systemctl daemon-reload
sudo systemctl restart kisko-doorbell
sudo systemctl status kisko-doorbell --no-pager
sudo journalctl -u kisko-doorbell -n 100 --no-pager
pgrep -af 'kisko-doorbell|rtl_433'
```

The process listing must not contain the Slack token. Ring the installed button and confirm that one notification is delivered for each press.

After the manual live check passes, create and push the tag from the workstation:

```shell
git tag -a v0.5.1 -m "Release v0.5.1" <release-commit>
git push origin refs/tags/v0.5.1
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matiaskorhonen/kisko-doorbell.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

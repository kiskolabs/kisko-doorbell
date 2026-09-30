#!/usr/bin/env ruby

require "fileutils"
require "json"
require "open3"
require "optparse"
require "pathname"
require "shellwords"
require "time"

require_relative "../../lib/kisko/doorbell/version"

module KiskoDoorbellRelease
  PROJECT_ROOT = File.expand_path("../..", __dir__)

  class Error < StandardError; end
  class CommandError < Error; end

  class Configuration
    HOST_PATTERN = /\A(?:[A-Za-z0-9._-]+@)?[A-Za-z0-9._-]+\z/
    NAME_PATTERN = /\A[A-Za-z0-9_.@-]+\z/

    attr_reader :host, :repository, :service, :token_file, :executable, :progress_path

    def self.parse(arguments)
      new.tap { |configuration| configuration.parse!(arguments) }
    rescue OptionParser::ParseError => error
      raise Error, error.message
    end

    def initialize
      @repository = "/home/pi/kisko-doorbell"
      @service = "kisko-doorbell"
      @token_file = "/etc/kisko-doorbell/slack-token"
      @executable = "/usr/local/bin/kisko-doorbell"
      @use_sudo = false
      @restart_progress = false
    end

    def parse!(arguments)
      parser.parse!(arguments)
      validate!
      self
    end

    def use_sudo?
      @use_sudo
    end

    def restart_progress?
      @restart_progress
    end

    def parser
      OptionParser.new do |options|
        options.banner = "Usage: usr/bin/release.rb --host USER@HOST [options]"
        options.on("--host TARGET", "SSH target, for example root@doorbell") { |value| @host = value }
        options.on("--repository PATH", "Target checkout (default: #{@repository})") { |value| @repository = value }
        options.on("--service NAME", "systemd service (default: #{@service})") { |value| @service = value }
        options.on("--token-file PATH", "Restricted token file (default: #{@token_file})") { |value| @token_file = value }
        options.on("--executable PATH", "Installed executable (default: #{@executable})") { |value| @executable = value }
        options.on("--progress PATH", "Override the local progress file") { |value| @progress_path = value }
        options.on("--sudo", "Use sudo for gem installation and systemd operations") { @use_sudo = true }
        options.on("--restart-progress", "Start this release's progress record again") { @restart_progress = true }
        options.on_tail("-h", "--help", "Show this message") do
          puts options
          exit
        end
      end
    end

    def validate!
      raise Error, "--host is required" unless host
      raise Error, "invalid SSH target: #{host.inspect}" unless HOST_PATTERN.match?(host) && !host.start_with?("-")
      raise Error, "repository must be an absolute path" unless absolute_path?(repository)
      raise Error, "token file must be an absolute path" unless absolute_path?(token_file)
      raise Error, "executable must be an absolute path" unless absolute_path?(executable)
      raise Error, "invalid systemd service name" unless NAME_PATTERN.match?(service)
    end

    def absolute_path?(value)
      value && !value.include?("\0") && !value.include?("\n") && Pathname.new(value).absolute?
    end
  end

  class Progress
    attr_reader :path

    def initialize(path:, fingerprint:, restart: false)
      @path = path
      @fingerprint = fingerprint
      @data = restart ? fresh_data : load_data
      verify_fingerprint!
      persist
    end

    def run(name)
      return :skipped if complete?(name)

      record(name, "running", "started_at" => timestamp)
      result = yield
      record(name, "complete", "finished_at" => timestamp)
      result
    rescue StandardError => error
      record(name, "failed", "finished_at" => timestamp, "error_type" => error.class.name)
      raise
    end

    def complete?(name)
      @data.dig("steps", name, "status") == "complete"
    end

    private

    def load_data
      return fresh_data unless File.file?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      raise Error, "progress file is invalid; use --restart-progress to replace it"
    end

    def fresh_data
      {"fingerprint" => @fingerprint, "steps" => {}, "created_at" => timestamp}
    end

    def verify_fingerprint!
      return if @data["fingerprint"] == @fingerprint

      raise Error, "progress belongs to a different release; use --restart-progress to replace it"
    end

    def record(name, status, attributes)
      @data["steps"][name] = {"status" => status}.merge(attributes)
      @data["updated_at"] = timestamp
      persist
    end

    def persist
      FileUtils.mkdir_p(File.dirname(path))
      temporary_path = "#{path}.tmp-#{Process.pid}"
      File.write(temporary_path, JSON.pretty_generate(@data) + "\n", mode: "w", perm: 0o600)
      File.rename(temporary_path, path)
    ensure
      FileUtils.rm_f(temporary_path) if temporary_path && File.exist?(temporary_path)
    end

    def timestamp
      Time.now.utc.iso8601
    end
  end

  class CommandRunner
    TOKEN_PATTERN = /xox[baprs]-[A-Za-z0-9-]+/

    def initialize(output: $stdout)
      @output = output
    end

    def run(command, label:, directory: nil, environment: {}, input: nil, show_output: true)
      options = {stdin_data: input.to_s}
      options[:chdir] = directory if directory
      stdout, stderr, status = Open3.capture3(environment, *command, **options)
      print_output(stdout, stderr) if show_output
      return stdout if status.success?

      raise CommandError, "#{label} failed with exit status #{status.exitstatus}"
    rescue Errno::ENOENT => error
      raise CommandError, "#{label} could not start: #{error.message}"
    end

    private

    def print_output(*streams)
      content = streams.reject(&:empty?).join("\n").gsub(TOKEN_PATTERN, "[REDACTED SLACK TOKEN]")
      @output.puts(content) unless content.empty?
    end
  end

  class LiveCheck
    def self.confirm(input: $stdin, output: $stdout)
      output.puts "Ring the installed doorbell and confirm exactly one Slack notification arrives."
      output.print "Type yes after the live check: "
      answer = input.gets
      return true if answer && answer.strip == "yes"

      raise Error, "live doorbell check was not confirmed"
    end
  end

  class Release
    def initialize(configuration, runner: CommandRunner.new, input: $stdin, output: $stdout)
      @configuration = configuration
      @runner = runner
      @input = input
      @output = output
      @version = Kisko::Doorbell::VERSION
      @tag = "v#{@version}"
    end

    def run
      commit = verify_local_release!
      progress = Progress.new(
        path: progress_path,
        fingerprint: fingerprint(commit),
        restart: @configuration.restart_progress?
      )

      step(progress, "local-checks") { run_local_checks }
      step(progress, "target-preflight") { run_remote(remote_preflight, "target preflight") }
      step(progress, "target-checkout") { run_remote(remote_checkout(commit), "target checkout") }
      step(progress, "gem-build") { run_remote(remote_build, "target gem build") }
      step(progress, "gem-install") { run_remote(remote_install, "target gem installation") }
      step(progress, "service-restart") { run_remote(remote_restart, "target service restart") }
      step(progress, "deployment-verification") { run_remote(remote_verification, "deployment verification") }
      step(progress, "live-doorbell-check") { LiveCheck.confirm(input: @input, output: @output) }
      step(progress, "release-tag") { create_and_push_tag(commit) }

      @output.puts "Release #{@tag} completed on #{@configuration.host}."
      @output.puts "Progress: #{progress.path}"
      true
    end

    private

    def verify_local_release!
      status = local(["git", "status", "--porcelain"], "worktree check", show_output: false)
      raise Error, "worktree is not clean; commit the complete release first" unless status.empty?

      branch = local(["git", "branch", "--show-current"], "branch lookup", show_output: false).strip
      raise Error, "release must run from master, not #{branch.inspect}" unless branch == "master"

      commit = local(["git", "rev-parse", "HEAD"], "HEAD lookup", show_output: false).strip
      remote_branch = local(
        ["git", "ls-remote", "--exit-code", "origin", "refs/heads/master"],
        "remote master lookup",
        show_output: false
      )
      raise Error, "push master before releasing #{commit}" unless remote_branch.split.first == commit

      verify_existing_tag(commit)

      commit
    end

    def verify_existing_tag(commit)
      local_tag = local(["git", "tag", "--list", @tag], "local release tag lookup", show_output: false).strip
      unless local_tag.empty?
        tag_commit = local(["git", "rev-parse", "#{@tag}^{commit}"], "release tag lookup", show_output: false).strip
        raise Error, "#{@tag} does not point to HEAD #{commit}" unless tag_commit == commit
      end

      remote_tags = local(
        ["git", "ls-remote", "origin", "refs/tags/#{@tag}", "refs/tags/#{@tag}^{}"],
        "remote release tag lookup",
        show_output: false
      )
      return if remote_tags.empty?

      remote_commit = remote_tags.lines.find { |line| line.end_with?("refs/tags/#{@tag}^{}\n") }&.split&.first
      remote_commit ||= remote_tags.lines.find { |line| line.end_with?("refs/tags/#{@tag}\n") }&.split&.first
      raise Error, "origin/#{@tag} does not point to HEAD #{commit}" unless remote_commit == commit
    end

    def run_local_checks
      local(["bundle", "exec", "rake"], "Ruby checks")
      local(["trunk", "check", "--all"], "Trunk checks")
      local(["pray", "verify", "--strict"], "Pray verification", environment: {"RBENV_VERSION" => "3.4.6"})
    end

    def remote_preflight
      <<~SHELL
        set -eu
        command -v git >/dev/null
        command -v ruby >/dev/null
        command -v gem >/dev/null
        command -v systemctl >/dev/null
        test -d #{quoted(@configuration.repository)}/.git
        test -r #{quoted(@configuration.token_file)}
        systemctl cat #{quoted(@configuration.service)} | grep -Fq #{quoted("KISKO_DOORBELL_SLACK_TOKEN_FILE=#{@configuration.token_file}")}
        if systemctl cat #{quoted(@configuration.service)} | grep -Fq -- '--slack-token='; then
          echo 'The systemd unit still passes the Slack token in an argument.' >&2
          exit 1
        fi
      SHELL
    end

    def remote_checkout(commit)
      <<~SHELL
        set -eu
        cd #{quoted(@configuration.repository)}
        test -z "$(git status --porcelain)"
        git fetch --tags origin master
        git cat-file -e #{quoted("#{commit}^{commit}")}
        git checkout --detach #{quoted(commit)}
      SHELL
    end

    def remote_build
      <<~SHELL
        set -eu
        cd #{quoted(@configuration.repository)}
        gem build kisko-doorbell.gemspec
        test -f #{quoted(gem_filename)}
      SHELL
    end

    def remote_install
      <<~SHELL
        set -eu
        cd #{quoted(@configuration.repository)}
        #{privileged("gem install --conservative --no-document #{quoted("./#{gem_filename}")}")}
      SHELL
    end

    def remote_restart
      <<~SHELL
        set -eu
        #{privileged("systemctl daemon-reload")}
        #{privileged("systemctl restart #{quoted(@configuration.service)}")}
      SHELL
    end

    def remote_verification
      expected_version = "kisko-doorbell v#{@version}"
      <<~SHELL
        set -eu
        systemctl is-active --quiet #{quoted(@configuration.service)}
        test "$(#{quoted(@configuration.executable)} --version)" = #{quoted(expected_version)}
        main_pid="$(systemctl show --property=MainPID --value #{quoted(@configuration.service)})"
        test "$main_pid" -gt 0
        if tr '\0' '\n' < "/proc/$main_pid/cmdline" | grep -Fq -- '--slack-token='; then
          echo 'The running service still exposes the Slack token in an argument.' >&2
          exit 1
        fi
      SHELL
    end

    def run_remote(script, label)
      @runner.run(["ssh", @configuration.host, "sh", "-s"], label: label, input: script)
    end

    def create_and_push_tag(commit)
      verify_existing_tag(commit)
      existing_tag = local(["git", "tag", "--list", @tag], "local release tag lookup", show_output: false)
      if existing_tag.strip.empty?
        local(["git", "tag", "-a", @tag, "-m", "Release #{@tag}"], "release tag creation")
      end
      local(["git", "push", "origin", "refs/tags/#{@tag}"], "release tag push")
    end

    def local(command, label, environment: {}, show_output: true)
      @runner.run(
        command,
        label: label,
        directory: PROJECT_ROOT,
        environment: environment,
        show_output: show_output
      )
    end

    def step(progress, name)
      if progress.complete?(name)
        @output.puts "SKIP #{name} (already complete)"
        return :skipped
      end

      @output.puts "START #{name}"
      result = progress.run(name) { yield }
      @output.puts "DONE  #{name}"
      result
    rescue StandardError
      @output.puts "FAIL  #{name}"
      raise
    end

    def fingerprint(commit)
      {
        "commit" => commit,
        "version" => @version,
        "tag" => @tag,
        "host" => @configuration.host,
        "repository" => @configuration.repository,
        "service" => @configuration.service
      }
    end

    def progress_path
      return File.expand_path(@configuration.progress_path, PROJECT_ROOT) if @configuration.progress_path

      safe_host = @configuration.host.gsub(/[^A-Za-z0-9_.-]/, "_")
      File.join(PROJECT_ROOT, "tmp", "releases", "#{safe_host}-#{@tag}.json")
    end

    def gem_filename
      "kisko-doorbell-#{@version}.gem"
    end

    def privileged(command)
      @configuration.use_sudo? ? "sudo #{command}" : command
    end

    def quoted(value)
      Shellwords.escape(value)
    end
  end

  class CLI
    def self.run(arguments)
      configuration = Configuration.parse(arguments)
      Release.new(configuration).run
      0
    rescue Error => error
      warn "Release stopped: #{error.message}"
      1
    rescue Interrupt
      warn "Release interrupted. Run the same command to resume."
      130
    end
  end
end

exit KiskoDoorbellRelease::CLI.run(ARGV) if $PROGRAM_NAME == __FILE__

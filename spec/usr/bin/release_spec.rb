require "spec_helper"
require "json"
require "stringio"
require "tmpdir"

require File.expand_path("../../../usr/bin/release", __dir__)

RSpec.describe KiskoDoorbellRelease do
  describe KiskoDoorbellRelease::Configuration do
    it "accepts a conventional SSH target" do
      configuration = described_class.parse(["--host", "root@doorbell"])

      expect(configuration.host).to eq("root@doorbell")
    end

    it "rejects a target that could add SSH options" do
      expect do
        described_class.parse(["--host", "-oProxyCommand=unexpected"])
      end.to raise_error(KiskoDoorbellRelease::Error, /invalid SSH target/)
    end
  end

  describe KiskoDoorbellRelease::Progress do
    it "resumes completed steps for the same release" do
      Dir.mktmpdir do |directory|
        path = File.join(directory, "progress.json")
        progress = described_class.new(path: path, fingerprint: {"commit" => "abc123"})
        executions = 0

        progress.run("checks") { executions += 1 }
        resumed = described_class.new(path: path, fingerprint: {"commit" => "abc123"})
        result = resumed.run("checks") { executions += 1 }

        expect(result).to eq(:skipped)
        expect(executions).to eq(1)
      end
    end

    it "records failure state without persisting command output" do
      Dir.mktmpdir do |directory|
        path = File.join(directory, "progress.json")
        progress = described_class.new(path: path, fingerprint: {"commit" => "abc123"})

        expect do
          progress.run("install") { raise KiskoDoorbellRelease::CommandError, "xoxb-sensitive-output" }
        end.to raise_error(KiskoDoorbellRelease::CommandError)

        stored_progress = File.read(path)
        expect(JSON.parse(stored_progress).dig("steps", "install", "status")).to eq("failed")
        expect(stored_progress).not_to include("sensitive-output")
      end
    end
  end

  describe KiskoDoorbellRelease::LiveCheck do
    it "requires an explicit confirmation after the physical test" do
      output = StringIO.new

      expect do
        described_class.confirm(input: StringIO.new("no\n"), output: output)
      end.to raise_error(KiskoDoorbellRelease::Error, /not confirmed/)

      expect(described_class.confirm(input: StringIO.new("yes\n"), output: output)).to eq(true)
    end
  end

  describe KiskoDoorbellRelease::Release do
    it "builds, installs, restarts, verifies, and requests the physical check" do
      Dir.mktmpdir do |directory|
        runner = Class.new do
          attr_reader :calls

          def initialize
            @calls = []
          end

          def run(command, label:, **options)
            @calls << {command: command, label: label, options: options}
            return "" if label == "worktree check"
            return "master\n" if label == "branch lookup"
            return "abc123\n" if label == "HEAD lookup"
            return "abc123\trefs/heads/master\n" if label == "remote master lookup"

            ""
          end
        end.new
        output = StringIO.new
        configuration = KiskoDoorbellRelease::Configuration.parse(
          ["--host", "root@doorbell", "--progress", File.join(directory, "release.json")]
        )

        result = described_class.new(
          configuration,
          runner: runner,
          input: StringIO.new("yes\n"),
          output: output
        ).run

        remote_commands = runner.calls.filter_map { |call| call.dig(:options, :input) }.join("\n")
        expect(result).to eq(true)
        expect(remote_commands).to include("gem build kisko-doorbell.gemspec")
        expect(remote_commands).to include("gem install --conservative --no-document")
        expect(remote_commands).not_to include("gem install --local")
        expect(remote_commands).to include("systemctl restart kisko-doorbell")
        expect(remote_commands).to include("KISKO_DOORBELL_SLACK_TOKEN_FILE")
        expect(remote_commands).to include("git checkout --detach abc123")
        expect(runner.calls).to include(
          hash_including(command: ["git", "tag", "-a", "v0.5.1", "-m", "Release v0.5.1"])
        )
        expect(runner.calls).to include(
          hash_including(command: ["git", "push", "origin", "refs/tags/v0.5.1"])
        )
        expect(output.string).to include("Type yes after the live check")
      end
    end
  end
end

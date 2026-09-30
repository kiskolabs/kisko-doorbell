require "tempfile"

RSpec.describe Kisko::Doorbell::CLI do
  subject(:cli) do
    described_class.new(
      doorbell_id: 2_810_647,
      logger: logger,
      test_mode: test_mode
    )
  end

  let(:logger) { instance_double(TTY::Logger, fatal: nil, info: nil, success: nil) }
  let(:test_mode) { false }

  it "configures rtl_433 for the Nexa transmitter" do
    expect(cli.rtl_433_arguments).to eq(
      ["-R", "96", "-M", "newmodel", "-M", "protocol", "-F", "json", "-f", "433920000", "-s", "250000"]
    )
  end

  context "in test mode" do
    let(:test_mode) { true }

    it "replays the captured Nexa signal" do
      arguments = cli.rtl_433_arguments

      expect(arguments.last(2)).to eq(
        ["-r", File.expand_path("../../../signals/g006_433.92M_250k.cu8", __dir__)]
      )
    end
  end

  describe "Slack credentials" do
    it "loads the token from a file without logging it" do
      Tempfile.create("kisko-doorbell-slack-token") do |file|
        file.chmod(0o600)
        file.write("file-secret\n")
        file.close

        configured_cli = described_class.new(
          doorbell_id: 2_810_647,
          logger: logger,
          slack_channel: "#doorbell",
          slack_token_file: file.path
        )

        expect(configured_cli.check_slack).to be(true)
        expect(configured_cli.slack_token).to eq("file-secret")
        expect(logger).to have_received(:success).with(
          "Slack configured",
          source: "file",
          channel: "#doorbell"
        )
      end
    end

    it "rejects an unreadable token file" do
      configured_cli = described_class.new(
        doorbell_id: 2_810_647,
        logger: logger,
        slack_channel: "#doorbell",
        slack_token_file: "/missing/slack-token"
      )

      expect(configured_cli.check_slack).to be(false)
      expect(logger).to have_received(:fatal).with(
        "Slack token file unreadable",
        path: "/missing/slack-token",
        error: kind_of(String)
      )
    end
  end
end

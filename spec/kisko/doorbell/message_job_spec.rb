RSpec.describe Kisko::Doorbell::MessageJob do
  subject(:job) { described_class.new }

  let(:logger) { instance_double(TTY::Logger, debug: nil, success: nil) }
  let(:event) do
    {
      "model" => "Nexa-Security",
      "id" => 2_810_647,
      "state" => state
    }
  end
  let(:state) { "ON" }

  before do
    allow(job).to receive(:logger).and_return(logger)
    allow(job).to receive(:notify_slack)
  end

  it "notifies Slack for an ON event from the configured transmitter" do
    perform

    expect(job).to have_received(:notify_slack)
  end

  it "rejects an OFF event from the configured transmitter" do
    event["state"] = "OFF"

    perform

    expect(job).not_to have_received(:notify_slack)
  end

  it "rejects an ON event from another transmitter" do
    event["id"] = 123

    perform

    expect(job).not_to have_received(:notify_slack)
  end

  def perform
    job.perform(
      line: JSON.generate(event),
      doorbell_id: 2_810_647,
      slack_token: "unused",
      slack_channel: "unused",
      store_path: "unused"
    )
  end
end

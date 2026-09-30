RSpec.describe Kisko::Doorbell::CLI do
  subject(:cli) do
    described_class.new(
      doorbell_id: 2_810_647,
      logger: logger,
      test_mode: test_mode
    )
  end

  let(:logger) { instance_double(TTY::Logger, info: nil) }
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
end

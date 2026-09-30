# frozen_string_literal: true

require "rubocop"
require_relative "../../lib/rubocop/cop/kisko/file_length"

RSpec.describe "Kisko file length cops" do
  def offenses_for(cop_class, source, configuration)
    config = RuboCop::Config.new(configuration)
    team = RuboCop::Cop::Team.new([cop_class.new(config)], config)
    processed_source = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, "example.rb")

    team.investigate(processed_source).offenses
  end

  it "warns without adding an offense between the preferred and hard limits" do
    configuration = {"Kisko/FileLengthWarning" => {"Max" => 3, "HardMax" => 5}}

    expect do
      expect(offenses_for(RuboCop::Cop::Kisko::FileLengthWarning, "one\ntwo\nthree\nfour\n",
                          configuration)).to be_empty
    end.to output(/LOC warning zone/).to_stderr

    expect do
      offenses_for(RuboCop::Cop::Kisko::FileLengthWarning, "one\ntwo\nthree\nfour\nfive\nsix\n", configuration)
    end.not_to output.to_stderr
  end

  it "fails above the hard limit" do
    configuration = {"Kisko/FileLengthLimit" => {"Max" => 3}}

    expect(offenses_for(RuboCop::Cop::Kisko::FileLengthLimit, "one\ntwo\nthree\n", configuration)).to be_empty
    expect(offenses_for(RuboCop::Cop::Kisko::FileLengthLimit, "one\ntwo\nthree\nfour\n", configuration).size).to eq(1)
  end
end

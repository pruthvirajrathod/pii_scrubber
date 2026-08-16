# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::IndianPan do
  subject(:detector) { described_class.new }

  let(:valid_individual_pan) { "ABCPE1234F" }
  let(:valid_company_pan) { "ABCCE1234F" }
  let(:invalid_holder_pan) { "ABCZE1234F" }
  let(:invalid_length_pan) { "ABCP1234F" }

  describe "#valid?" do
    it "validates properly structured Indian PAN numbers with valid taxpayer category" do
      expect(detector.valid?(valid_individual_pan)).to be true
      expect(detector.valid?(valid_company_pan)).to be true
    end

    it "rejects PAN strings with invalid 4th character entity type" do
      expect(detector.valid?(invalid_holder_pan)).to be false
    end

    it "rejects invalid lengths" do
      expect(detector.valid?(invalid_length_pan)).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(valid_individual_pan, strategy: :placeholder)).to eq("[REDACTED:INDIAN_PAN]")
    end

    it "masks the 4th and 5th characters while preserving prefix and sequence" do
      expect(detector.replace(valid_individual_pan, strategy: :mask)).to eq("ABC**1234F")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "detects and redacts Indian PAN in text" do
      text = "Tax invoice PAN number: ABCPE1234F for billing."
      result = PiiScrubber.scrub(text)
      expect(result).to eq("Tax invoice PAN number: [REDACTED:INDIAN_PAN] for billing.")
    end
  end
end

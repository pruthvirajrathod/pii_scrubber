# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::IndianAadhaar do
  subject(:detector) { described_class.new }

  let(:valid_aadhaar) { "367598345017" }
  let(:formatted_aadhaar) { "3675 9834 5017" }
  let(:hyphenated_aadhaar) { "3675-9834-5017" }
  let(:invalid_checksum_aadhaar) { "367598345018" }
  let(:invalid_first_digit_0) { "067598345017" }
  let(:invalid_first_digit_1) { "167598345017" }

  describe "#valid?" do
    it "validates valid 12-digit Aadhaar numbers using Verhoeff checksum" do
      expect(detector.valid?(valid_aadhaar)).to be true
      expect(detector.valid?(formatted_aadhaar)).to be true
      expect(detector.valid?(hyphenated_aadhaar)).to be true
      expect(detector.valid?("9876 5432 1096")).to be true
    end

    it "rejects 12-digit numbers failing the Verhoeff checksum" do
      expect(detector.valid?(invalid_checksum_aadhaar)).to be false
    end

    it "rejects numbers starting with 0 or 1" do
      expect(detector.valid?(invalid_first_digit_0)).to be false
      expect(detector.valid?(invalid_first_digit_1)).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(valid_aadhaar, strategy: :placeholder)).to eq("[REDACTED:INDIAN_AADHAAR]")
    end

    it "masks the first 8 digits and preserves the last 4 digits" do
      expect(detector.replace(valid_aadhaar, strategy: :mask)).to eq("****-****-5017")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "detects and redacts Aadhaar number in text" do
      text = "Citizen UIDAI Aadhaar: 3675 9834 5017 verified."
      result = PiiScrubber.scrub(text)
      expect(result).to eq("Citizen UIDAI Aadhaar: [REDACTED:INDIAN_AADHAAR] verified.")
    end
  end
end

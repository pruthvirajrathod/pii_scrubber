# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::Iban do
  subject(:detector) { described_class.new }

  # Valid IBAN examples across multiple countries
  let(:valid_gb_iban) { "GB82WEST12345698765432" }
  let(:formatted_gb_iban) { "GB82 WEST 1234 5698 7654 32" }
  let(:valid_de_iban) { "DE89370400440532013000" }
  let(:invalid_iban) { "GB82WEST12345698765433" } # Invalid check digit

  describe "#valid?" do
    it "validates continuous valid IBANs with Modulo-97 check" do
      expect(detector.valid?(valid_gb_iban)).to be true
      expect(detector.valid?(valid_de_iban)).to be true
    end

    it "validates formatted IBANs with spaces" do
      expect(detector.valid?(formatted_gb_iban)).to be true
    end

    it "rejects invalid IBANs with corrupt check digits" do
      expect(detector.valid?(invalid_iban)).to be false
    end

    it "rejects too short or too long strings" do
      expect(detector.valid?("GB82123")).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(valid_gb_iban, strategy: :placeholder)).to eq("[REDACTED:IBAN]")
    end

    it "masks middle characters preserving country code and last 4 characters" do
      masked = detector.replace(valid_gb_iban, strategy: :mask)
      expect(masked).to start_with("GB82")
      expect(masked).to end_with("5432")
      expect(masked).to include("**************")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "detects and redacts IBAN numbers in text" do
      text = "Please transfer the invoice amount to account GB82WEST12345698765432."
      result = PiiScrubber.scrub(text)
      expect(result).to eq("Please transfer the invoice amount to account [REDACTED:IBAN].")
    end
  end
end

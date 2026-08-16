# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::CanadianSin do
  subject(:detector) { described_class.new }

  let(:valid_sin) { "130-692-544" }
  let(:space_sin) { "130 692 544" }
  let(:continuous_sin) { "130692544" }
  let(:invalid_luhn_sin) { "130-692-545" }
  let(:invalid_prefix_sin_0) { "030-692-544" }
  let(:invalid_prefix_sin_8) { "830-692-544" }

  describe "#valid?" do
    it "validates valid Canadian SIN numbers with Luhn check" do
      expect(detector.valid?(valid_sin)).to be true
      expect(detector.valid?(space_sin)).to be true
      expect(detector.valid?(continuous_sin)).to be true
    end

    it "rejects SINs failing the Luhn checksum" do
      expect(detector.valid?(invalid_luhn_sin)).to be false
    end

    it "rejects SINs starting with disallowed digits 0 or 8" do
      expect(detector.valid?(invalid_prefix_sin_0)).to be false
      expect(detector.valid?(invalid_prefix_sin_8)).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(valid_sin, strategy: :placeholder)).to eq("[REDACTED:CANADIAN_SIN]")
    end

    it "masks the first 6 digits and preserves the last 3 digits" do
      expect(detector.replace(valid_sin, strategy: :mask)).to eq("***-***-544")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "detects and redacts Canadian SIN in text" do
      text = "Taxpayer SIN is 130-692-544."
      result = PiiScrubber.scrub(text)
      expect(result).to eq("Taxpayer SIN is [REDACTED:CANADIAN_SIN].")
    end
  end
end

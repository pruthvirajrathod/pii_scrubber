# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::UkNino do
  subject(:detector) { described_class.new }

  let(:valid_nino) { "QQ123456A" }
  let(:formatted_nino) { "QQ 12 34 56 A" }
  let(:hyphenated_nino) { "QQ-12-34-56-A" }
  let(:disallowed_prefix_nino) { "GB123456A" }
  let(:invalid_char_nino) { "QQ123456Z" } # 'Z' is not valid suffix (must be A-D)

  describe "#valid?" do
    it "validates properly structured UK NINOs" do
      expect(detector.valid?(valid_nino)).to be true
      expect(detector.valid?(formatted_nino)).to be true
      expect(detector.valid?(hyphenated_nino)).to be true
    end

    it "rejects disallowed administrative prefixes (GB, BG, NK, KN, TN, NT, ZZ)" do
      expect(detector.valid?(disallowed_prefix_nino)).to be false
      expect(detector.valid?("ZZ123456A")).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(valid_nino, strategy: :placeholder)).to eq("[REDACTED:UK_NINO]")
    end

    it "masks the numeric digits preserving prefix and suffix" do
      expect(detector.replace(valid_nino, strategy: :mask)).to eq("QQ******A")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "detects and redacts UK NINO in sentences" do
      text = "Citizen NINO record is QQ 12 34 56 C on file."
      result = PiiScrubber.scrub(text)
      expect(result).to eq("Citizen NINO record is [REDACTED:UK_NINO] on file.")
    end
  end
end

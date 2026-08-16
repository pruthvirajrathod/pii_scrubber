# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::CreditCard do
  subject(:detector) { described_class.new }

  it "validates valid credit card numbers using Luhn check" do
    valid_visa = "4532015112830366"
    expect(detector.valid?(valid_visa)).to be true
  end

  it "rejects invalid credit card numbers failing Luhn check" do
    invalid_card = "4532015112830367"
    expect(detector.valid?(invalid_card)).to be false
  end

  it "masks credit cards preserving last 4 digits" do
    valid_visa = "4532015112830366"
    masked = detector.replace(valid_visa, strategy: :mask)
    expect(masked).to eq("************0366")
  end
end

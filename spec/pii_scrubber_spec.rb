# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber do
  it "has a version number" do
    expect(PiiScrubber::VERSION).not_to be nil
  end

  describe ".configure" do
    it "allows custom detector list and strategy configuration" do
      PiiScrubber.configure do |config|
        config.strategy = :mask
        config.detectors = [:email]
      end

      expect(PiiScrubber.configuration.strategy).to eq(:mask)
      expect(PiiScrubber.configuration.detectors).to eq([:email])
    end

    it "supports regional presets like :uk, :in, :ca, :eu, :secrets" do
      PiiScrubber.configure do |config|
        config.use_preset(:in)
      end

      expect(PiiScrubber.configuration.detectors).to include(:indian_pan, :indian_aadhaar, :email, :phone)
      expect(PiiScrubber.configuration.detectors).not_to include(:uk_nino, :canadian_sin)
    end

    it "supports enable_detector and disable_detector helpers" do
      PiiScrubber.configure do |config|
        config.disable_detector(:email, :phone)
      end

      expect(PiiScrubber.configuration.detectors).not_to include(:email, :phone)

      PiiScrubber.configure do |config|
        config.enable_detector(:email)
      end

      expect(PiiScrubber.configuration.detectors).to include(:email)
    end
  end

  describe ".scrub" do
    it "scrubs emails from strings" do
      result = PiiScrubber.scrub("Contact user at alice@example.com for info.")
      expect(result).to eq("Contact user at [REDACTED:EMAIL] for info.")
    end

    it "scrubs phone numbers from strings" do
      result = PiiScrubber.scrub("Call me at 555-123-4567 tomorrow.")
      expect(result).to eq("Call me at [REDACTED:PHONE] tomorrow.")
    end

    it "scrubs SSNs from strings" do
      result = PiiScrubber.scrub("SSN is 123-45-6789.")
      expect(result).to eq("SSN is [REDACTED:SSN].")
    end

    it "scrubs IP addresses from strings" do
      result = PiiScrubber.scrub("Server IP is 192.168.1.50.")
      expect(result).to eq("Server IP is [REDACTED:IP_ADDRESS].")
    end
  end
end

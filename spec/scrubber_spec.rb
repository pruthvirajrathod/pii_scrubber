# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Scrubber do
  subject(:scrubber) { described_class.new }

  describe "#scrub with nested data structures" do
    it "recursively scrubs nested hashes and arrays" do
      data = {
        user: {
          name: "John Doe",
          email: "john@example.com",
          contacts: ["555-987-6543", "jane@example.com"]
        }
      }

      result = scrubber.scrub(data)
      expect(result).to eq({
        user: {
          name: "John Doe",
          email: "[REDACTED:EMAIL]",
          contacts: ["[REDACTED:PHONE]", "[REDACTED:EMAIL]"]
        }
      })
    end

    it "respects ignored_keys when scrubbing hashes" do
      data = {
        email: "support@company.com",
        user_email: "john@example.com"
      }

      result = scrubber.scrub(data, ignored_keys: [:email])
      expect(result).to eq({
        email: "support@company.com",
        user_email: "[REDACTED:EMAIL]"
      })
    end

    it "scrubs embedded JSON strings transparently" do
      json_payload = '{"user":"alice@example.com","phone":"555-123-4567"}'
      result = scrubber.scrub(json_payload)
      expect(result).to include("[REDACTED:EMAIL]")
      expect(result).to include("[REDACTED:PHONE]")
      expect(JSON.parse(result)).to eq({
        "user" => "[REDACTED:EMAIL]",
        "phone" => "[REDACTED:PHONE]"
      })
    end

    it "supports HMAC hashing strategy" do
      email = "alice@example.com"
      result1 = scrubber.scrub(email, strategy: :hash, hmac_salt: "secret_salt")
      result2 = scrubber.scrub(email, strategy: :hash, hmac_salt: "secret_salt")

      expect(result1).to start_with("[ANON:")
      expect(result1).to eq(result2) # Deterministic hashing
    end

    it "automatically redacts values for sensitive hash keys like password or auth_token" do
      params = {
        username: "johndoe",
        password: "supersecretpassword123",
        auth_token: "xyz987654321"
      }

      result = scrubber.scrub(params)
      expect(result[:username]).to eq("johndoe")
      expect(result[:password]).to eq("[REDACTED:PASSWORD]")
      expect(result[:auth_token]).to eq("[REDACTED:AUTH_TOKEN]")
    end

    it "supports custom Proc / Lambda strategy" do
      custom_proc = ->(match, name) { "<HIDDEN_#{name.upcase}>" }
      result = scrubber.scrub("Contact test@example.com", strategy: custom_proc)
      expect(result).to eq("Contact <HIDDEN_EMAIL>")
    end

    it "supports add_rule DSL helper for custom detectors" do
      PiiScrubber.configure do |config|
        config.add_rule(:employee_id, /EMP-\d{4}/)
      end

      result = PiiScrubber.scrub("Employee code is EMP-5678.")
      expect(result).to eq("Employee code is [REDACTED:EMPLOYEE_ID].")
    end
  end
end

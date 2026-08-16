# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Vault do
  let(:original_text) { "Please send invoice to Alice at alice@example.com or call 555-123-4567." }

  describe ".anonymize" do
    it "replaces PII with unique vault token placeholders" do
      session = described_class.anonymize(original_text)

      expect(session.text).not_to include("alice@example.com")
      expect(session.text).not_to include("555-123-4567")
      expect(session.text).to match(/\[PII_VAULT_EMAIL_[0-9a-f]{8}\]/)
      expect(session.text).to match(/\[PII_VAULT_PHONE_[0-9a-f]{8}\]/)
    end

    it "creates a valid mappings dictionary in session" do
      session = described_class.anonymize(original_text)

      expect(session.mappings.values).to include("alice@example.com", "555-123-4567")
    end
  end

  describe "#restore" do
    it "restores original PII values from LLM response text containing placeholders" do
      session = PiiScrubber.anonymize(original_text)
      mock_llm_response = "Confirmed. I have sent the message to #{session.text}."

      restored = session.restore(mock_llm_response)

      expect(restored).to eq("Confirmed. I have sent the message to #{original_text}.")
      expect(restored).to include("alice@example.com")
      expect(restored).to include("555-123-4567")
    end

    it "restores nested hashes and arrays" do
      payload = { email: "john@example.com", phone: "555-987-6543" }
      session = PiiScrubber.anonymize(payload)

      llm_data_response = {
        status: "success",
        processed_data: session.text
      }

      restored = session.restore(llm_data_response)

      expect(restored[:processed_data][:email]).to eq("john@example.com")
      expect(restored[:processed_data][:phone]).to eq("555-987-6543")
    end
  end

  describe "Session serialization" do
    it "serializes to hash and deserializes back retaining full restore capability" do
      session = PiiScrubber.anonymize(original_text)
      serialized_hash = session.to_h

      rehydrated_session = PiiScrubber::Vault::Session.from_h(serialized_hash)
      restored = rehydrated_session.restore(session.text)

      expect(restored).to eq(original_text)
    end
  end
end

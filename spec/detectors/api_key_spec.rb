# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::ApiKey do
  it "detects and redacts OpenAI API keys" do
    text = "Key is sk-proj-1234567890abcdef1234567890abcdef12345678"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("Key is [REDACTED:API_KEY]")
  end

  it "detects and redacts AWS Access Key IDs" do
    text = "AWS key: AKIAIOSFODNN7EXAMPLE"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("AWS key: [REDACTED:API_KEY]")
  end

  it "detects and redacts GitHub Personal Access Tokens" do
    text = "Github token: ghp_1234567890abcdefghijklmnopqrstuvwxyz"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("Github token: [REDACTED:API_KEY]")
  end

  it "detects and redacts Hugging Face Access Tokens" do
    text = "HuggingFace key: hf_abcdefghijklmnopqrstuvwxyz0123456789"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("HuggingFace key: [REDACTED:API_KEY]")
  end

  it "detects and redacts SendGrid API keys" do
    text = "Sendgrid key: SG.abcdefghijklmnopqrstuv.1234567890abcdefghijklmnopqrstuvwxyz012345678"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("Sendgrid key: [REDACTED:API_KEY]")
  end

  it "detects and redacts Twilio Account SIDs and Auth Tokens" do
    text = "Twilio credentials: AC0123456789abcdef0123456789abcdef and SKabcdef0123456789abcdef0123456789"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("Twilio credentials: [REDACTED:API_KEY] and [REDACTED:API_KEY]")
  end

  it "detects and redacts GitLab Personal Access Tokens" do
    text = "GitLab PAT: glpat-abcdefghijklmnopqrst1234"
    result = PiiScrubber.scrub(text)
    expect(result).to eq("GitLab PAT: [REDACTED:API_KEY]")
  end
end

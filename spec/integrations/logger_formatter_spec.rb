# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe PiiScrubber::Integrations::LoggerFormatter do
  it "sanitizes log outputs automatically" do
    buffer = StringIO.new
    logger = Logger.new(buffer)
    logger.formatter = described_class.new

    logger.info("User logged in with email john@example.com and ip 192.168.1.100")

    log_output = buffer.string
    expect(log_output).to include("[REDACTED:EMAIL]")
    expect(log_output).to include("[REDACTED:IP_ADDRESS]")
    expect(log_output).not_to include("john@example.com")
  end
end

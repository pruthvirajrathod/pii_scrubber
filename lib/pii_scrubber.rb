# frozen_string_literal: true

require_relative "pii_scrubber/version"
require_relative "pii_scrubber/configuration"
require_relative "pii_scrubber/detectors/base"
require_relative "pii_scrubber/detectors/email"
require_relative "pii_scrubber/detectors/phone"
require_relative "pii_scrubber/detectors/credit_card"
require_relative "pii_scrubber/detectors/ssn"
require_relative "pii_scrubber/detectors/api_key"
require_relative "pii_scrubber/detectors/ip_address"
require_relative "pii_scrubber/detectors/iban"
require_relative "pii_scrubber/detectors/uk_nino"
require_relative "pii_scrubber/detectors/canadian_sin"
require_relative "pii_scrubber/detectors/indian_pan"
require_relative "pii_scrubber/detectors/indian_aadhaar"
require_relative "pii_scrubber/detectors/database_url"
require_relative "pii_scrubber/scrubber"
require_relative "pii_scrubber/integrations/logger_formatter"
require_relative "pii_scrubber/integrations/faraday_middleware"
require_relative "pii_scrubber/integrations/rack_middleware"
require_relative "pii_scrubber/vault"

module PiiScrubber
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def scrub(data, **options)
      Scrubber.new(configuration).scrub(data, **options)
    end

    def anonymize(data, **options)
      Vault.new(configuration).anonymize(data, **options)
    end

    def restore(data, session:)
      session.restore(data)
    end
  end
end

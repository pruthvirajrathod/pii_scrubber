# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class Phone < Base
      # Matches international and common domestic phone number formats
      PHONE_REGEX = /(?:\+|\b)(?:[0-9]{1,3}[ -]?)?\(?[0-9]{3}\)?[ -]?[0-9]{3}[ -]?[0-9]{4}\b/

      def initialize
        super(name: :phone)
      end

      def patterns
        [PHONE_REGEX]
      end

      def valid?(match)
        # Ensure it has between 10 and 15 digits
        digits = match.gsub(/\D/, "")
        digits.length >= 10 && digits.length <= 15
      end
    end
  end
end

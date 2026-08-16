# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class Ssn < Base
      SSN_REGEX = /\b(?!000|666|9\d{2})\d{3}[ -]?(?!00)\d{2}[ -]?(?!0000)\d{4}\b/

      def initialize
        super(name: :ssn)
      end

      def patterns
        [SSN_REGEX]
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        digits = match.scan(/\d/)
        return super if digits.size < 4

        last_four = digits.last(4).join
        "***-**-#{last_four}"
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class UkNino < Base
      # Matches UK National Insurance numbers (e.g., QQ123456A, QQ 12 34 56 A, QQ-12-34-56-A)
      UK_NINO_REGEX = /\b[A-Za-z]{2}[ -]?[0-9]{2}[ -]?[0-9]{2}[ -]?[0-9]{2}[ -]?[A-Da-d]\b/

      DISALLOWED_PREFIXES = %w[GB BG NK KN TN NT ZZ].freeze
      DISALLOWED_CHARS = %w[D F I U V].freeze

      def initialize
        super(name: :uk_nino)
      end

      def patterns
        [UK_NINO_REGEX]
      end

      def valid?(match)
        sanitized = match.gsub(/[\s-]/, "").upcase
        return false unless sanitized.length == 9

        prefix = sanitized[0..1]
        return false if DISALLOWED_PREFIXES.include?(prefix)

        # Characters D, F, I, U, V are disallowed in first or second position
        # Character O is disallowed in second position
        return false if DISALLOWED_CHARS.include?(sanitized[0])
        return false if (DISALLOWED_CHARS + ["O"]).include?(sanitized[1])

        true
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        sanitized = match.gsub(/[\s-]/, "").upcase
        return super if sanitized.length != 9

        prefix = sanitized[0..1]
        suffix = sanitized[-1]
        "#{prefix}#{mask_char * 6}#{suffix}"
      end
    end
  end
end

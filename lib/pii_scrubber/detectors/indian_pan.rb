# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class IndianPan < Base
      # Matches 10-character Indian Permanent Account Numbers (e.g. ABCDE1234F)
      PAN_REGEX = /\b[A-Za-z]{5}[0-9]{4}[A-Za-z]\b/

      VALID_HOLDER_TYPES = %w[C P H F A T B L J G].freeze

      def initialize
        super(name: :indian_pan)
      end

      def patterns
        [PAN_REGEX]
      end

      def valid?(match)
        pan = match.upcase
        return false unless pan.length == 10

        holder_type = pan[3]
        VALID_HOLDER_TYPES.include?(holder_type)
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        pan = match.upcase
        return super if pan.length != 10

        prefix = pan[0..2]
        digits = pan[5..8]
        suffix = pan[9]
        "#{prefix}#{mask_char * 2}#{digits}#{suffix}"
      end
    end
  end
end

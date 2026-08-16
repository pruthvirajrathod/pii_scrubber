# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class CanadianSin < Base
      # Matches 9-digit Canadian Social Insurance Numbers (e.g. 046-454-286, 046 454 286, 046454286)
      SIN_REGEX = /\b[0-9]{3}[ -]?[0-9]{3}[ -]?[0-9]{3}\b/

      def initialize
        super(name: :canadian_sin)
      end

      def patterns
        [SIN_REGEX]
      end

      def valid?(match)
        digits = match.scan(/\d/).map(&:to_i)
        return false unless digits.size == 9

        # First digit cannot be 0 or 8 in valid Canadian SINs
        return false if [0, 8].include?(digits.first)

        luhn_valid?(digits)
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        digits = match.scan(/\d/)
        return super if digits.size != 9

        last_three = digits.last(3).join
        "#{mask_char * 3}-#{mask_char * 3}-#{last_three}"
      end

      private

      def luhn_valid?(digits)
        checksum = 0
        reverse_digits = digits.reverse

        reverse_digits.each_with_index do |digit, index|
          if index.odd?
            doubled = digit * 2
            checksum += doubled > 9 ? doubled - 9 : doubled
          else
            checksum += digit
          end
        end

        (checksum % 10).zero?
      end
    end
  end
end

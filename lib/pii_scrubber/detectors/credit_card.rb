# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class CreditCard < Base
      # Matches 13-19 digit card numbers separated by optional dashes or spaces
      CREDIT_CARD_REGEX = /\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})\b/
      GENERIC_CARD_REGEX = /\b(?:\d[ -]*?){13,19}\b/

      def initialize
        super(name: :credit_card)
      end

      def patterns
        [CREDIT_CARD_REGEX, GENERIC_CARD_REGEX]
      end

      def valid?(match)
        digits = match.scan(/\d/).map(&:to_i)
        return false unless digits.size >= 13 && digits.size <= 19

        luhn_valid?(digits)
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        digits = match.scan(/\d/)
        return super if digits.size < 4

        # Show last 4 digits
        last_four = digits.last(4).join
        "#{mask_char * 12}#{last_four}"
      end

      private

      # Luhn algorithm implementation for checking credit card checksum
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

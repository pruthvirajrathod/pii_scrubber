# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class Iban < Base
      # Matches international bank account numbers (15-34 alphanumeric chars with optional spacing/hyphens)
      IBAN_REGEX = /\b[A-Za-z]{2}\d{2}(?:[ -]?[A-Za-z0-9]{4}){2,7}(?:[ -]?[A-Za-z0-9]{1,4})?\b/

      def initialize
        super(name: :iban)
      end

      def patterns
        [IBAN_REGEX]
      end

      def valid?(match)
        sanitized = match.gsub(/[\s-]/, "").upcase
        return false unless sanitized.length.between?(15, 34)
        return false unless sanitized.match?(/\A[A-Z]{2}\d{2}[A-Z0-9]+\z/)

        modulo97_valid?(sanitized)
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        sanitized = match.gsub(/[\s-]/, "").upcase
        return super if sanitized.length < 8

        prefix = sanitized[0..3] # Country code + check digits
        suffix = sanitized[-4..-1]
        masked_middle = mask_char * (sanitized.length - 8)
        "#{prefix}#{masked_middle}#{suffix}"
      end

      private

      # ISO 7064 Modulo 97-10 checksum validation
      def modulo97_valid?(iban)
        # Move first 4 characters (country + check digits) to the end
        rearranged = iban[4..-1] + iban[0..3]

        # Convert letters to digits: A=10, B=11, ..., Z=35
        num_str = rearranged.each_char.map do |ch|
          if ch >= "A" && ch <= "Z"
            (ch.ord - 55).to_s
          else
            ch
          end
        end.join

        # Calculate remainder modulo 97
        num_str.to_i % 97 == 1
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class IndianAadhaar < Base
      # Matches 12-digit Indian Aadhaar numbers starting with 2-9
      AADHAAR_REGEX = /\b[2-9][0-9]{3}[ -]?[0-9]{4}[ -]?[0-9]{4}\b/

      # Verhoeff algorithm multiplication table
      D_TABLE = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
        [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
        [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
        [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
        [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
        [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
        [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
        [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
      ].freeze

      # Verhoeff algorithm permutation table
      P_TABLE = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
        [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
        [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
        [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
        [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
        [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
        [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
      ].freeze

      def initialize
        super(name: :indian_aadhaar)
      end

      def patterns
        [AADHAAR_REGEX]
      end

      def valid?(match)
        digits = match.scan(/\d/).map(&:to_i)
        return false unless digits.size == 12

        # First digit cannot be 0 or 1
        return false if [0, 1].include?(digits.first)

        verhoeff_valid?(digits)
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        digits = match.scan(/\d/)
        return super if digits.size != 12

        last_four = digits.last(4).join
        "#{mask_char * 4}-#{mask_char * 4}-#{last_four}"
      end

      private

      # Validates 12-digit number using Verhoeff checksum algorithm
      def verhoeff_valid?(digits)
        checksum = 0
        digits.reverse.each_with_index do |digit, index|
          checksum = D_TABLE[checksum][P_TABLE[index % 8][digit]]
        end
        checksum.zero?
      end
    end
  end
end

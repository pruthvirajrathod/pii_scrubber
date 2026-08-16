# frozen_string_literal: true

require "digest"

module PiiScrubber
  module Detectors
    class Base
      attr_reader :name

      def initialize(name:)
        @name = name.to_sym
      end

      # Returns array of Regexp objects for matching
      def patterns
        []
      end

      # Validates if the regex match is genuinely a PII instance (prevents false positives)
      def valid?(_match)
        true
      end

      # Generates replacement text for the match based on strategy
      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        if strategy.is_a?(Proc)
          return strategy.call(match, name)
        end

        case strategy
        when :placeholder
          "[REDACTED:#{name.to_s.upcase}]"
        when :mask
          mask_value(match, mask_char: mask_char)
        when :hash
          digest = hmac_salt ? Digest::SHA256.hexdigest("#{hmac_salt}:#{match}")[0..7] : Digest::SHA256.hexdigest(match)[0..7]
          "[ANON:#{digest}]"
        else
          "[REDACTED:#{name.to_s.upcase}]"
        end
      end

      protected

      def mask_value(val, mask_char: "*")
        return mask_char * val.length if val.length <= 4

        # Keep first and last character visible, mask middle
        first = val[0]
        last = val[-1]
        masked_length = [val.length - 2, 1].max
        "#{first}#{mask_char * masked_length}#{last}"
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class IpAddress < Base
      IPV4_REGEX = /\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/
      IPV6_REGEX = /\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b/

      def initialize
        super(name: :ip_address)
      end

      def patterns
        [IPV4_REGEX, IPV6_REGEX]
      end

      def valid?(match)
        # Optional check: skip localhost (127.0.0.1 or ::1) if needed, otherwise valid IP
        true
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        if match.include?(".") # IPv4
          octets = match.split(".")
          "#{octets[0]}.#{octets[1]}.#{mask_char * 3}.#{mask_char * 3}"
        else
          super
        end
      end
    end
  end
end

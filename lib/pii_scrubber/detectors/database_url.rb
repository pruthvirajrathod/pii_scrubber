# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class DatabaseUrl < Base
      # Matches connection strings with embedded user/password credentials
      DATABASE_URL_REGEX = /\b(?:postgres(?:ql)?|mysql2?|mongodb(?:\+srv)?|rediss?|amqps?|mssql|sqlserver):\/\/(?:[^:\s\/]+:)?(?:[^@\s\/]+)@[^\s\/:]+(?::\d+)?(?:\/[^\s"']*)?/i

      def initialize
        super(name: :database_url)
      end

      def patterns
        [DATABASE_URL_REGEX]
      end

      def valid?(match)
        # Ensure it contains @ separating credentials from host
        match.include?("@") && match.include?("://")
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        case strategy
        when :mask
          # Mask password while preserving scheme, username, host and database
          match.sub(%r{://(?:([^:@\s/]+):)?([^@\s/]+)@}) do
            user_part = $1 ? "#{$1}:" : ""
            "://#{user_part}#{mask_char * 8}@"
          end
        when :placeholder
          "[REDACTED:DATABASE_URL]"
        else
          super
        end
      end
    end
  end
end

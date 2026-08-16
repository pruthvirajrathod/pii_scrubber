# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class Email < Base
      EMAIL_REGEX = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/

      def initialize
        super(name: :email)
      end

      def patterns
        [EMAIL_REGEX]
      end

      def replace(match, strategy: :placeholder, mask_char: "*", hmac_salt: nil)
        return super unless strategy == :mask

        user, domain = match.split("@", 2)
        return super unless user && domain

        masked_user = mask_value(user, mask_char: mask_char)
        domain_parts = domain.split(".")
        masked_domain_name = mask_value(domain_parts[0], mask_char: mask_char)
        tld = domain_parts[1..-1].join(".")

        "#{masked_user}@#{masked_domain_name}.#{tld}"
      end
    end
  end
end

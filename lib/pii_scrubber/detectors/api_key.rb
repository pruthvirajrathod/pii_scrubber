# frozen_string_literal: true

require_relative "base"

module PiiScrubber
  module Detectors
    class ApiKey < Base
      PATTERNS = [
        # AWS Access Key ID
        /\b(AKIA[0-9A-Z]{16})\b/,
        # OpenAI API Key
        /\b(sk-[a-zA-Z0-9]{32,}|sk-proj-[a-zA-Z0-9\-_]{32,})\b/,
        # Anthropic API Key
        /\b(sk-ant-api[0-9a-zA-Z\-_]{32,})\b/,
        # Google API Key
        /\b(AIzaSy[0-9A-Za-z\-_]{35})\b/,
        # GitHub Tokens
        /\b(gh[pousr]_[a-zA-Z0-9]{36,40})\b/,
        # Stripe Keys
        /\b([sr]k_live_[0-9a-zA-Z]{24,34})\b/,
        # JWT Bearer Token
        /\b(Bearer\s+eyJ[a-zA-Z0-9\-_]+\.eyJ[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+)\b/,
        # Generic Slack / Slack Bot Token
        /\b(xox[baprs]-[0-9a-zA-Z]{10,48})\b/,
        # Hugging Face Access Token
        /\b(hf_[a-zA-Z0-9]{34,})\b/,
        # SendGrid API Key
        /\b(SG\.[a-zA-Z0-9_\-]{16,32}\.[a-zA-Z0-9_\-]{32,64})\b/,
        # Twilio API Key / SID
        /\b((?:AC|SK)[a-f0-9]{32})\b/,
        # Mailgun API Key
        /\b(key-[a-zA-Z0-9]{32})\b/,
        # GitLab Personal Access Token
        /\b(glpat-[0-9a-zA-Z\-_]{20,})\b/,
        # RSA / PEM Private Keys
        /-----BEGIN (?:RSA|EC|DSA|OPENSSH) PRIVATE KEY-----[[\s\S]]*?-----END (?:RSA|EC|DSA|OPENSSH) PRIVATE KEY-----/
      ].freeze

      def initialize
        super(name: :api_key)
      end

      def patterns
        PATTERNS
      end
    end
  end
end

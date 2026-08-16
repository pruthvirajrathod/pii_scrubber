# frozen_string_literal: true

module PiiScrubber
  module Integrations
    class FaradayMiddleware
      SENSITIVE_HEADERS = %w[authorization cookie x-api-key x-auth-token set-cookie].freeze

      attr_reader :app, :options

      def initialize(app, options = {})
        @app = app
        @options = options
      end

      def call(env)
        sanitize_request(env)

        @app.call(env).on_complete do |response_env|
          sanitize_response(response_env)
        end
      end

      private

      def sanitize_request(env)
        if env.request_headers
          SENSITIVE_HEADERS.each do |hdr|
            env.request_headers.keys.each do |key|
              if key.to_s.downcase == hdr
                env.request_headers[key] = PiiScrubber.scrub(env.request_headers[key].to_s, **options)
              end
            end
          end
        end

        if env.body.is_a?(String) || env.body.is_a?(Hash)
          env.body = PiiScrubber.scrub(env.body, **options)
        end
      end

      def sanitize_response(env)
        if env.response_body.is_a?(String) || env.response_body.is_a?(Hash)
          env.response_body = PiiScrubber.scrub(env.response_body, **options)
        end
      end
    end
  end
end

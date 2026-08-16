# frozen_string_literal: true

module PiiScrubber
  module Integrations
    class RackMiddleware
      attr_reader :app, :options

      def initialize(app, options = {})
        @app = app
        @options = options
      end

      def call(env)
        sanitize_rack_env(env)
        @app.call(env)
      end

      private

      def sanitize_rack_env(env)
        # Sanitize query string parameters
        if env["QUERY_STRING"] && !env["QUERY_STRING"].empty?
          env["QUERY_STRING"] = PiiScrubber.scrub(env["QUERY_STRING"], **options)
        end

        # Sanitize Rack request params (ActionDispatch / Rack::Request)
        if env["rack.request.form_hash"].is_a?(Hash)
          env["rack.request.form_hash"] = PiiScrubber.scrub(env["rack.request.form_hash"], **options)
        end

        if env["action_dispatch.request.parameters"].is_a?(Hash)
          env["action_dispatch.request.parameters"] = PiiScrubber.scrub(env["action_dispatch.request.parameters"], **options)
        end
      end
    end
  end
end

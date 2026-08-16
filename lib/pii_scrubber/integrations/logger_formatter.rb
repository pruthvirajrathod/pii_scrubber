# frozen_string_literal: true

require "logger"

module PiiScrubber
  module Integrations
    class LoggerFormatter < ::Logger::Formatter
      attr_reader :original_formatter, :options

      def initialize(original_formatter = nil, **options)
        super()
        @original_formatter = original_formatter || ::Logger::Formatter.new
        @options = options
      end

      def call(severity, time, program_name, message)
        scrubbed_msg = format_message(message)
        if original_formatter.respond_to?(:call)
          original_formatter.call(severity, time, program_name, scrubbed_msg)
        else
          super(severity, time, program_name, scrubbed_msg)
        end
      end

      private

      def format_message(msg)
        case msg
        when String
          PiiScrubber.scrub(msg, **options)
        when Hash, Array
          PiiScrubber.scrub(msg, **options)
        when Exception
          "#{msg.class}: #{PiiScrubber.scrub(msg.message, **options)}"
        else
          msg.inspect
        end
      end
    end
  end
end

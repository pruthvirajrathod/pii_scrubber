# frozen_string_literal: true

require "securerandom"
require_relative "vault/session"

module PiiScrubber
  class Vault
    attr_reader :config

    def initialize(config = PiiScrubber.configuration)
      @config = config
    end

    def self.anonymize(data, **options)
      new.anonymize(data, **options)
    end

    def anonymize(data, **override_options)
      mappings = {}
      anonymized_data = anonymize_node(data, mappings: mappings, options: override_options)
      Session.new(text: anonymized_data, mappings: mappings)
    end

    private

    def anonymize_node(data, mappings:, options:)
      case data
      when String
        anonymize_string(data, mappings: mappings, options: options)
      when Hash
        data.each_with_object({}) do |(key, value), acc|
          acc[key] = anonymize_node(value, mappings: mappings, options: options)
        end
      when Array
        data.map { |item| anonymize_node(item, mappings: mappings, options: options) }
      else
        data
      end
    end

    def anonymize_string(str, mappings:, options:)
      return str if str.nil? || str.empty?

      result = str.dup
      scrubber = Scrubber.new(config)
      detectors = scrubber.send(:build_detectors)

      detectors.each do |detector|
        detector.patterns.each do |pattern|
          result.gsub!(pattern) do |match|
            if detector.valid?(match)
              placeholder = generate_placeholder(detector.name)
              mappings[placeholder] = match
              placeholder
            else
              match
            end
          end
        end
      end

      result
    end

    def generate_placeholder(detector_name)
      short_id = SecureRandom.hex(4)
      "[PII_VAULT_#{detector_name.to_s.upcase}_#{short_id}]"
    end
  end
end

# frozen_string_literal: true

require "json"

module PiiScrubber
  class Scrubber
    BUILT_IN_DETECTORS = {
      email: Detectors::Email,
      phone: Detectors::Phone,
      ssn: Detectors::Ssn,
      credit_card: Detectors::CreditCard,
      api_key: Detectors::ApiKey,
      ip_address: Detectors::IpAddress,
      iban: Detectors::Iban,
      uk_nino: Detectors::UkNino,
      canadian_sin: Detectors::CanadianSin,
      indian_pan: Detectors::IndianPan,
      indian_aadhaar: Detectors::IndianAadhaar,
      database_url: Detectors::DatabaseUrl
    }.freeze

    attr_reader :config

    def initialize(config = PiiScrubber.configuration)
      @config = config
      @active_detectors = build_detectors
    end

    def scrub(data, **override_options)
      strategy = override_options[:strategy] || config.strategy
      mask_char = override_options[:mask_char] || config.mask_char
      hmac_salt = override_options[:hmac_salt] || config.hmac_salt
      ignored_keys = (override_options[:ignored_keys] || config.ignored_keys).map(&:to_s)

      case data
      when String
        scrub_string(data, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt)
      when Hash
        scrub_hash(data, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt, ignored_keys: ignored_keys)
      when Array
        data.map { |item| scrub(item, **override_options) }
      else
        data
      end
    end

    private

    def build_detectors
      detectors = []
      enabled_names = config.detectors.map(&:to_sym)

      enabled_names.each do |name|
        detector_class = BUILT_IN_DETECTORS[name]
        detectors << detector_class.new if detector_class
      end

      config.custom_rules.each do |rule|
        if rule.is_a?(Detectors::Base)
          detectors << rule
        elsif rule.is_a?(Hash) && rule[:name] && rule[:pattern]
          detectors << create_custom_detector(rule[:name], rule[:pattern], rule[:validator])
        end
      end

      detectors
    end

    def create_custom_detector(name, pattern, validator = nil)
      detector = Detectors::Base.new(name: name)
      pattern_arr = Array(pattern)
      detector.define_singleton_method(:patterns) { pattern_arr }
      if validator
        detector.define_singleton_method(:valid?) { |match| validator.call(match) }
      end
      detector
    end

    def scrub_string(str, strategy:, mask_char:, hmac_salt:)
      return str if str.nil? || str.empty?

      # If string is valid JSON, attempt JSON-aware scrubbing first
      if json_string?(str)
        begin
          parsed = JSON.parse(str)
          scrubbed = scrub(parsed, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt)
          return JSON.generate(scrubbed)
        rescue JSON::ParserError
          # Fallback to normal string replacement if parsing fails
        end
      end

      result = str.dup

      @active_detectors.each do |detector|
        detector.patterns.each do |pattern|
          result.gsub!(pattern) do |match|
            if detector.valid?(match)
              detector.replace(match, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt)
            else
              match
            end
          end
        end
      end

      result
    end

    def scrub_hash(hash, strategy:, mask_char:, hmac_salt:, ignored_keys:)
      hash.each_with_object({}) do |(key, value), acc|
        str_key = key.to_s
        if ignored_keys.include?(str_key)
          acc[key] = value
        elsif config.redact_sensitive_hash_keys && sensitive_key?(str_key)
          acc[key] = redact_sensitive_value(value, key_name: str_key, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt)
        else
          acc[key] = scrub(value, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt, ignored_keys: ignored_keys)
        end
      end
    end

    def sensitive_key?(key_str)
      config.sensitive_key_patterns.any? { |pattern| key_str.match?(pattern) }
    end

    def redact_sensitive_value(value, key_name:, strategy:, mask_char:, hmac_salt:)
      detector = Detectors::Base.new(name: key_name)
      if value.is_a?(String)
        detector.replace(value, strategy: strategy, mask_char: mask_char, hmac_salt: hmac_salt)
      else
        "[REDACTED:#{key_name.upcase}]"
      end
    end

    def json_string?(str)
      trimmed = str.strip
      (trimmed.start_with?("{") && trimmed.end_with?("}")) || (trimmed.start_with?("[") && trimmed.end_with?("]"))
    end
  end
end

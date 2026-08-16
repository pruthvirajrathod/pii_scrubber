# frozen_string_literal: true

module PiiScrubber
  class Configuration
    attr_accessor :detectors, :strategy, :mask_char, :hmac_salt, :ignored_keys, :custom_rules, :sensitive_key_patterns, :redact_sensitive_hash_keys

    ALL_DETECTORS = %i[
      database_url
      api_key
      iban
      credit_card
      canadian_sin
      ssn
      uk_nino
      indian_pan
      indian_aadhaar
      email
      phone
      ip_address
    ].freeze

    PRESETS = {
      all: ALL_DETECTORS,
      us: %i[email phone ssn credit_card api_key ip_address database_url],
      uk: %i[email phone uk_nino iban credit_card api_key ip_address database_url],
      eu: %i[email phone iban credit_card api_key ip_address database_url],
      ca: %i[email phone canadian_sin credit_card api_key ip_address database_url],
      in: %i[email phone indian_pan indian_aadhaar credit_card api_key ip_address database_url],
      finance: %i[credit_card iban],
      secrets: %i[api_key database_url]
    }.freeze

    def initialize
      @detectors = ALL_DETECTORS.dup
      @strategy = :placeholder
      @mask_char = "*"
      @hmac_salt = nil
      @ignored_keys = []
      @custom_rules = []
      @redact_sensitive_hash_keys = true
      @sensitive_key_patterns = [
        /password/i,
        /secret/i,
        /auth_token/i,
        /access_token/i,
        /bearer_token/i,
        /private_key/i,
        /cvv/i,
        /card_number/i
      ]
    end

    def use_preset(preset_name)
      preset = PRESETS[preset_name.to_sym]
      raise ArgumentError, "Unknown preset: #{preset_name}. Valid presets: #{PRESETS.keys.join(', ')}" unless preset

      @detectors = preset.dup
    end

    def enable_detector(*names)
      names.each do |name|
        sym = name.to_sym
        @detectors << sym unless @detectors.include?(sym)
      end
    end

    def disable_detector(*names)
      syms = names.map(&:to_sym)
      @detectors.reject! { |d| syms.include?(d) }
    end

    def add_rule(name, pattern, &validator)
      @custom_rules << { name: name.to_sym, pattern: pattern, validator: validator }
    end
  end
end

# frozen_string_literal: true

require "securerandom"
require "time"

module PiiScrubber
  class Vault
    class Session
      attr_reader :id, :text, :mappings, :created_at

      def initialize(text:, mappings:, id: nil, created_at: nil)
        @id = id || SecureRandom.hex(8)
        @text = text
        @mappings = mappings || {}
        @created_at = created_at || Time.now.utc
      end

      # Restores original values in text, hashes, or arrays containing vault placeholders
      def restore(data)
        case data
        when String
          restore_string(data)
        when Hash
          restore_hash(data)
        when Array
          data.map { |item| restore(item) }
        else
          data
        end
      end

      # Serializes session for storing in Redis, Memcached, or Rails sessions
      def to_h
        {
          "id" => id,
          "text" => text,
          "mappings" => mappings,
          "created_at" => created_at.iso8601
        }
      end

      # Deserializes session from Hash
      def self.from_h(hash)
        return nil if hash.nil?

        new(
          id: hash["id"] || hash[:id],
          text: hash["text"] || hash[:text],
          mappings: hash["mappings"] || hash[:mappings] || {},
          created_at: hash["created_at"] ? Time.parse(hash["created_at"].to_s) : Time.now.utc
        )
      end

      private

      def restore_string(str)
        return str if str.nil? || str.empty? || mappings.empty?

        result = str.dup
        mappings.each do |placeholder, original_value|
          result.gsub!(placeholder, original_value.to_s)
        end
        result
      end

      def restore_hash(hash)
        hash.each_with_object({}) do |(key, value), acc|
          acc[key] = restore(value)
        end
      end
    end
  end
end

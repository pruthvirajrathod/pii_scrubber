# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Detectors::DatabaseUrl do
  subject(:detector) { described_class.new }

  let(:postgres_url) { "postgres://db_user:s3cr3t_pass!@db.production.internal:5432/main_db" }
  let(:mysql_url) { "mysql2://root:mypassword@127.0.0.1:3306/users_db" }
  let(:mongo_url) { "mongodb+srv://admin:clusterpass123@cluster0.mongodb.net/test" }
  let(:redis_url) { "redis://:supersecret@cache.internal:6379/0" }

  describe "#valid?" do
    it "identifies valid database connection strings containing credentials" do
      expect(detector.valid?(postgres_url)).to be true
      expect(detector.valid?(mysql_url)).to be true
      expect(detector.valid?(mongo_url)).to be true
      expect(detector.valid?(redis_url)).to be true
    end

    it "ignores regular URLs without database protocols" do
      expect(detector.valid?("https://example.com/api/test")).to be false
    end
  end

  describe "#replace" do
    it "replaces with placeholder strategy" do
      expect(detector.replace(postgres_url, strategy: :placeholder)).to eq("[REDACTED:DATABASE_URL]")
    end

    it "masks the password portion with mask strategy while preserving host & database structure" do
      masked = detector.replace(postgres_url, strategy: :mask)
      expect(masked).to eq("postgres://db_user:********@db.production.internal:5432/main_db")
      expect(masked).not_to include("s3cr3t_p@ss!")
    end
  end

  describe "End-to-end integration with PiiScrubber.scrub" do
    it "redacts database URLs in config or error strings" do
      log = "Database connection error to postgres://db_admin:supersecret123@db.aws.com:5432/production"
      result = PiiScrubber.scrub(log)
      expect(result).to eq("Database connection error to [REDACTED:DATABASE_URL]")
      expect(result).not_to include("supersecret123")
    end
  end
end

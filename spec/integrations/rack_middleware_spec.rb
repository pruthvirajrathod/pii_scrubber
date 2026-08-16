# frozen_string_literal: true

require "spec_helper"

RSpec.describe PiiScrubber::Integrations::RackMiddleware do
  let(:app) { ->(env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] } }
  subject(:middleware) { described_class.new(app) }

  it "sanitizes query string parameters in Rack env" do
    env = { "QUERY_STRING" => "email=john@example.com&user=john" }
    middleware.call(env)
    expect(env["QUERY_STRING"]).to include("[REDACTED:EMAIL]")
    expect(env["QUERY_STRING"]).not_to include("john@example.com")
  end

  it "sanitizes Rack request form hash parameters" do
    env = {
      "rack.request.form_hash" => {
        "user" => "john",
        "password" => "mysecretpass123",
        "email" => "john@example.com"
      }
    }
    middleware.call(env)
    form_hash = env["rack.request.form_hash"]
    expect(form_hash["user"]).to eq("john")
    expect(form_hash["password"]).to eq("[REDACTED:PASSWORD]")
    expect(form_hash["email"]).to eq("[REDACTED:EMAIL]")
  end
end

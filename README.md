# 🛡️ PiiScrubber

[![Gem Version](https://img.shields.io/gem/v/pii_scrubber.svg?color=blue)](https://rubygems.org/gems/pii_scrubber)
[![Gem Downloads](https://img.shields.io/gem/dt/pii_scrubber.svg?color=orange)](https://rubygems.org/gems/pii_scrubber)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**PiiScrubber** is a high-performance, pluggable Ruby gem for detecting and sanitizing Personally Identifiable Information (PII) and API secrets from strings, nested data structures, Rails logs, Faraday HTTP requests, and LLM prompt contexts.

---

## ✨ Features

- ✉️ **Email Addresses** (`user@example.com` → `[REDACTED:EMAIL]` or `j***@e***.com`)
- 📱 **Phone Numbers** (`+1-800-555-0199` → `[REDACTED:PHONE]`)
- 💳 **Credit Cards** (Supports Luhn algorithm checksum validation to eliminate false positives)
- 🪪 **US Social Security Numbers (SSN)** (`123-45-6789`)
- 🏦 **International Bank Account Numbers (IBAN)** (ISO 7064 Modulo-97 checksum validation for 80+ countries)
- 🇬🇧 **UK National Insurance Numbers (NINO)** (`QQ 12 34 56 A`)
- 🇨🇦 **Canadian Social Insurance Numbers (SIN)** (Luhn algorithm validated)
- 🇮🇳 **Indian Identifiers**:
  - **PAN Cards** (`ABCPE1234F` with taxpayer status validation)
  - **Aadhaar Numbers** (`3675 9834 5017` with Verhoeff algorithm checksum)
- 🗄️ **Database Connection Strings** (`postgres://user:pass@host:5432/db`, `mysql2://`, `mongodb://`, `redis://`)
- 🔑 **API Keys & Cloud Secrets** (AWS Access Keys, OpenAI `sk-`, Anthropic `sk-ant-`, Hugging Face `hf_`, SendGrid `SG.`, Twilio `AC`/`SK`, Mailgun `key-`, GitLab `glpat-`, GitHub `ghp_`, Stripe `sk_live_`, Bearer Tokens, RSA Private Keys)
- 🌐 **IP Addresses** (IPv4 & IPv6)
- 🌲 **Data Structure Support**: Recursively scrubs `String`, `Hash`, `Array`, and embedded `JSON`.
- 🔑 **Sensitive Key Redaction**: Automatically redacts values for hash keys matching sensitive terms (`password`, `auth_token`, `secret`, `cvv`, `pin`).
- 🌍 **Regional Configuration Presets**: Quick switch with `:us`, `:uk`, `:eu`, `:ca`, `:in`, `:finance`, `:secrets`, or `:all`.
- 🛠️ **Integrations**: Drop-in wrapper for `Logger` / Rails `ActiveSupport::Logger`, `Faraday` HTTP middleware, and `Rack` middleware.
- 💻 **CLI Utility**: Scrub log files directly from the command line (`cat app.log | pii_scrubber`).

---

## 📦 Installation

Add this line to your application's `Gemfile`:

```ruby
gem "pii_scrubber"
```

And then execute:

```bash
bundle install
```

---

## 🚀 Quick Start

### 1. Basic Usage

```ruby
require "pii_scrubber"

# Simple String Scrubbing
PiiScrubber.scrub("Please contact Jane Doe at jane@example.com or call 555-123-4567.")
# => "Please contact Jane Doe at [REDACTED:EMAIL] or call [REDACTED:PHONE]."

# Nested Hash & Sensitive Key Redaction
payload = {
  user: {
    username: "john_smith",
    password: "mysecretpassword123", # Key matches sensitive key pattern
    email: "john.smith@gmail.com",
    api_key: "sk-proj-1234567890abcdef1234567890abcdef12345678"
  }
}

PiiScrubber.scrub(payload)
# => {
#      user: {
#        username: "john_smith",
#        password: "[REDACTED:PASSWORD]",
#        email: "[REDACTED:EMAIL]",
#        api_key: "[REDACTED:API_KEY]"
#      }
#    }
```

---

### 2. Regional Presets & International PII

Easily configure detection for specific geographic regions or security profiles:

```ruby
PiiScrubber.configure do |config|
  # Use regional preset (:us, :uk, :eu, :ca, :in, :finance, :secrets, or :all)
  config.use_preset(:eu)

  # Or selectively enable/disable detectors
  config.enable_detector(:iban, :uk_nino)
  config.disable_detector(:ip_address)
end

# Multi-country detection with checksum validation
text = "IBAN: GB82WEST12345698765432, SIN: 130-692-544, DB: postgres://user:secret@localhost/db"
PiiScrubber.scrub(text)
# => "IBAN: [REDACTED:IBAN], SIN: [REDACTED:CANADIAN_SIN], DB: [REDACTED:DATABASE_URL]"
```

---

### 3. Custom Rules & Proc Redaction Strategy

```ruby
PiiScrubber.configure do |config|
  # Add custom rule via DSL
  config.add_rule(:employee_code, /EMP-\d{4}/)

  # Custom Proc strategy
  config.strategy = ->(match, detector_name) { "<HIDDEN_#{detector_name.to_s.upcase}>" }
end

PiiScrubber.scrub("Employee EMP-1234 email is test@company.com")
# => "Employee <HIDDEN_EMPLOYEE_CODE> email is <HIDDEN_EMAIL>"
```

---

### 4. 🤖 Reversible Anonymization Vault (For LLMs & APIs)

When sending user input to external LLMs (OpenAI, Anthropic, Gemini) or third-party APIs, anonymize PII before sending the prompt and **restore the real PII values** when rendering the response back to the user:

```ruby
# 1. Anonymize user prompt before sending to LLM
session = PiiScrubber.anonymize("Draft an email to Alice at alice@company.com or call 555-123-4567.")

session.text
# => "Draft an email to Alice at [PII_VAULT_EMAIL_a8f91234] or call [PII_VAULT_PHONE_b4c56789]."

# 2. Pass session.text to OpenAI / LLM
llm_response = "Confirmed! Email drafted for [PII_VAULT_EMAIL_a8f91234]."

# 3. Restore original PII into LLM output
restored_response = session.restore(llm_response)
# => "Confirmed! Email drafted for alice@company.com."
```

#### Redis / Session Storage Serialization

Vault sessions can be serialized and stored across asynchronous HTTP requests or background jobs:

```ruby
# Save to Redis / Cache
redis.set("vault:#{session.id}", session.to_h.to_json)

# Restore in background worker
saved_hash = JSON.parse(redis.get("vault:#{session.id}"))
session = PiiScrubber::Vault::Session.from_h(saved_hash)
final_output = session.restore(async_llm_response)
```

`pii_scrubber` supports three redaction strategies:
1. `:placeholder` (Default): `[REDACTED:EMAIL]`
2. `:mask`: Partial masking (`j***@g***.com` or `************0366`)
3. `:hash`: HMAC-SHA256 deterministic hash (`[ANON:a3b1f9e8]`)

```ruby
PiiScrubber.configure do |config|
  config.strategy = :mask
  config.mask_char = "*"
  config.detectors = [:email, :credit_card, :api_key]
  config.ignored_keys = [:company_email] # Skip scrubbing specific hash keys
end

PiiScrubber.scrub("Email: john@gmail.com")
# => "Email: j***@g***.com"
```

#### HMAC Anonymization Strategy

Useful when you need consistent anonymized tokens for tracking without revealing PII:

```ruby
PiiScrubber.scrub("User email: john@gmail.com", strategy: :hash, hmac_salt: "my_secret_salt")
# => "User email: [ANON:c74d0e2b]"
```

---

### 3. Rails Logger Integration

Sanitize all Rails production logs automatically by updating `config/environments/production.rb`:

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger.formatter = PiiScrubber::Integrations::LoggerFormatter.new
end
```

---

### 4. Faraday HTTP Client Integration

Prevent sensitive headers (`Authorization`, `Cookie`) and PII in request/response bodies from leaking into third-party services:

```ruby
conn = Faraday.new(url: "https://api.example.com") do |faraday|
  faraday.use PiiScrubber::Integrations::FaradayMiddleware, strategy: :placeholder
  faraday.adapter Faraday.default_adapter
end
```

---

### 5. CLI Executable

PiiScrubber comes with a command-line tool to clean log files on standard input or file paths:

```bash
# Pipe stdin
echo "User email is test@example.com and IP is 192.168.1.100" | pii_scrubber

# Process file with masking strategy
pii_scrubber -s mask production.log
```

---

## 🧪 Running Tests

To run the test suite:

```bash
bundle exec rspec
```

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

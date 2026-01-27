# =============================================================================
# Credentials Validation
# =============================================================================
#
# LEARNING NOTES:
#
# This initializer runs when Rails boots and verifies that all required
# credentials are present. If anything is missing, it fails fast with a
# clear error message instead of a cryptic runtime error later.
#
# Why this matters:
# - In production, a missing credential could cause a 500 error at runtime
# - Better to catch it at deploy/boot time with a helpful message
# - This is especially important for HIPAA — you want to know immediately
#   if something isn't configured, not discover it when a patient record
#   is being accessed
#
# How Rails credentials work:
# - Each environment can have its own encrypted credentials file
# - Rails.application.credentials returns the decrypted values
# - If the key file is missing, credentials will be empty
#
# =============================================================================

Rails.application.config.after_initialize do
  # Only enforce in production — development and test can use defaults
  if Rails.env.production?
    credentials = Rails.application.credentials

    # secret_key_base is critical — Rails won't function without it
    if credentials.secret_key_base.blank?
      raise <<~ERROR
        ❌ MISSING CREDENTIAL: secret_key_base

        Production requires a secret_key_base in encrypted credentials.

        To fix:
        1. Get the production key from your secure storage (NOT from Sparky!)
        2. Run: RAILS_ENV=production rails credentials:edit --environment production
        3. Ensure secret_key_base is set

        See config/credentials/TEMPLATE.yml for all required keys.
      ERROR
    end

    # Add more checks here as credentials are added:
    #
    # if credentials.dig(:database, :password).blank?
    #   raise "❌ MISSING CREDENTIAL: database.password"
    # end
    #
    # if credentials.dig(:aws, :access_key_id).blank?
    #   raise "❌ MISSING CREDENTIAL: aws.access_key_id"
    # end
  end
end

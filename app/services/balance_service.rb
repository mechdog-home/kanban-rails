# ============================================================================
# Service: BalanceService
# ============================================================================
#
# Queries AI provider APIs to fetch current balance information.
# Handles each provider's unique API format and authentication.
#
# LEARNING NOTES:
#
# Services in Rails are plain Ruby classes that encapsulate business logic.
# They live in app/services/ and follow single-responsibility principle.
#
# COMPARISON TO NODE.JS:
# - Express: You'd have a utils/balance.js file with exported functions
# - Rails: Service classes provide better organization and testability
#
# API ENDPOINTS:
# - Moonshot: GET https://api.moonshot.ai/v1/users/me/balance
# - OpenRouter: GET https://openrouter.ai/api/v1/credits
# - OpenAI: No public balance API (console only) - we return placeholder
# - Anthropic: No public balance API (console only) - we return placeholder
# - xAI: No public balance API (console only) - we return placeholder
#
# ============================================================================

require 'net/http'
require 'json'

class BalanceService
  # ==========================================================================
  # CONSTANTS
  # ==========================================================================
  
  PROVIDER_CONFIG = {
    moonshot: {
      name: 'Moonshot (Kimi)',
      base_url: 'https://api.moonshot.ai/v1',
      endpoint: '/users/me/balance',
      api_key_env: 'MOONSHOT_API_KEY',
      supports_balance_api: true
    },
    openrouter: {
      name: 'OpenRouter',
      base_url: 'https://openrouter.ai/api/v1',
      endpoint: '/credits',
      api_key_env: 'OPENROUTER_API_KEY',
      supports_balance_api: true
    },
    openai: {
      name: 'OpenAI (GPT)',
      base_url: 'https://api.openai.com/v1',
      endpoint: '/dashboard/billing/credit_grants',
      api_key_env: 'OPENAI_API_KEY',
      supports_balance_api: false, # No public API
      note: 'Check https://platform.openai.com/settings/organization/billing/overview'
    },
    anthropic: {
      name: 'Anthropic (Claude)',
      base_url: 'https://api.anthropic.com/v1',
      endpoint: nil,
      api_key_env: 'ANTHROPIC_API_KEY',
      supports_balance_api: false, # No public API
      note: 'Check https://console.anthropic.com/settings/billing'
    },
    xai: {
      name: 'xAI (Grok)',
      base_url: 'https://api.x.ai/v1',
      endpoint: nil,
      api_key_env: 'XAI_API_KEY',
      supports_balance_api: false, # No public API
      note: 'Check https://console.x.ai/billing'
    }
  }.freeze

  # ==========================================================================
  # CLASS METHODS
  # ==========================================================================
  
  # Query all providers and return balance information
  # Returns hash: { provider => { success: true/false, balance: x, ... } }
  def self.query_all
    results = {}
    
    PROVIDER_CONFIG.each do |provider_key, config|
      results[provider_key.to_s] = query_provider(provider_key)
    end
    
    results
  end
  
  # Query a single provider
  def self.query_provider(provider_key)
    config = PROVIDER_CONFIG[provider_key]
    
    return { success: false, error: 'Unknown provider' } unless config
    
    # Check if provider has balance API support
    unless config[:supports_balance_api]
      return {
        success: true, # Not an error, just not supported
        balance: nil,
        currency: 'USD',
        supports_api: false,
        note: config[:note],
        name: config[:name]
      }
    end
    
    # Check for API key
    api_key = ENV[config[:api_key_env]]
    
    if api_key.blank?
      return {
        success: false,
        error: "#{config[:api_key_env]} not configured",
        name: config[:name]
      }
    end
    
    # Query the API
    begin
      case provider_key
      when :moonshot
        query_moonshot(config, api_key)
      when :openrouter
        query_openrouter(config, api_key)
      else
        { success: false, error: 'Query not implemented', name: config[:name] }
      end
    rescue => e
      Rails.logger.error("[BalanceService] Error querying #{provider_key}: #{e.message}")
      {
        success: false,
        error: "API error: #{e.message}",
        name: config[:name]
      }
    end
  end
  
  # Store current balances in database
  def self.record_balances!
    results = query_all
    timestamp = Time.current
    
    results.each do |provider, data|
      # Skip if the query failed or doesn't support API
      next unless data[:success]
      
      ApiBalanceHistory.create!(
        provider: provider,
        balance: data[:balance] || 0,
        currency: data[:currency] || 'USD',
        metadata: data.except(:balance, :currency, :success, :error),
        success: data[:balance].present? || data[:supports_api] == false,
        error_message: data[:error],
        queried_at: timestamp
      )
    end
    
    results
  end

  # ==========================================================================
  # PRIVATE CLASS METHODS
  # ==========================================================================
  
  def self.query_moonshot(config, api_key)
    uri = URI("#{config[:base_url]}#{config[:endpoint]}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      
      # Moonshot returns: { "data": { "available_balance": 123.45, "currency": "CNY" } }
      # NOTE: Displayed as USD per user preference
      balance_data = data['data'] || data
      
      {
        success: true,
        balance: balance_data['available_balance']&.to_f || balance_data['balance']&.to_f,
        currency: 'USD',
        total_balance: balance_data['total_balance']&.to_f,
        name: config[:name],
        supports_api: true,
        raw: data
      }
    else
      {
        success: false,
        error: "HTTP #{response.code}: #{response.message}",
        name: config[:name]
      }
    end
  rescue JSON::ParserError => e
    {
      success: false,
      error: "Invalid JSON response: #{e.message}",
      name: config[:name]
    }
  end
  
  def self.query_openrouter(config, api_key)
    uri = URI("#{config[:base_url]}#{config[:endpoint]}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      
      # OpenRouter returns: { "data": { "total_credits": 10.0, "total_usage": 2.5 } }
      credits_data = data['data'] || data
      
      total = credits_data['total_credits']&.to_f || 0
      used = credits_data['total_usage']&.to_f || 0
      remaining = total - used
      
      {
        success: true,
        balance: remaining,
        currency: 'USD',
        total_credits: total,
        total_usage: used,
        name: config[:name],
        supports_api: true,
        raw: data
      }
    else
      {
        success: false,
        error: "HTTP #{response.code}: #{response.message}",
        name: config[:name]
      }
    end
  rescue JSON::ParserError => e
    {
      success: false,
      error: "Invalid JSON response: #{e.message}",
      name: config[:name]
    }
  end
  
  private_class_method :query_moonshot, :query_openrouter
end

class ShortLinkService
  ENCODE_API = '/create'.freeze
  DECODE_API = '/alias'.freeze

  def initialize(params = {})
    @params = params
  end

  private

  def body_request
    {
      url: @params[:url],
      domain: ENV['SHORT_LINK_SERVICE_DOMAIN'],
      api_token: ENV['SHORT_LINK_SERVICE_API_TOKEN'],
      description: 'string',
    }
  end

  def headers
    @headers ||= {
      'Content-Type' => 'application/json',
      'X-Request-ID' => SecureRandom.uuid
    }
  end

  def handle_error(extra = {})
    error_data = {
      error: extra[:error],
      code: extra[:code],
      response: extra[:response]
    }
    Rails.logger.error "#{self.class.name} Error: #{error_data.to_json}"
    {
      error: 'An error occurred during processing'
    }
  end
end
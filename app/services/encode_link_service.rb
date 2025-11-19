class EncodeLinkService < ShortLinkService
  def deliver
    RestClient.post(request_url, body_request.to_json, headers) do |response, _request, result|
      code = result.code.to_i
      if code == 200
        formatted_response(JSON.parse(response))
      else
        handle_error(code: code, response: response.as_json)
      end
    end
  rescue StandardError => e
    handle_error(error: e)
  end

  private

  def request_url
    @request_url ||= "#{ENV['SHORT_LINK_SERVICE_URL']}#{ENCODE_API}"
  end

  def formatted_response(res)
    {
      url: res.dig('data', 'tiny_url')
    }
  end
end
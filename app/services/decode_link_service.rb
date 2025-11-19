class DecodeLinkService < ShortLinkService
  def deliver
    RestClient.get(request_url) do |response, _request, result|
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
    return @request_url if @request_url
    url = "#{ENV['SHORT_LINK_SERVICE_URL']}#{DECODE_API}/#{ENV['SHORT_LINK_SERVICE_DOMAIN']}/#{@params[:alias_url]}"
    @request_url = url + "?api_token=#{ENV['SHORT_LINK_SERVICE_API_TOKEN']}"
  end

  def formatted_response(res)
    {
      url: res.dig('data', 'url')
    }
  end
end
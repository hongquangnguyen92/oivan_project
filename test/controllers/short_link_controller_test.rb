require 'test_helper'

class ShortLinkControllerTest < ActionDispatch::IntegrationTest
  test 'should encode a valid long URL and return 200 OK' do
    # Define the payload (JSON request body)
    post_data = { url: 'https://codesubmit.io/library/react' }

    # Call POST request
    post encode_url, params: post_data, as: :json

    # Check HTTP status code
    assert_response 200

    # Check JSON response structure
    response_json = JSON.parse(response.body)
    assert response_json.key?('url'), "Response is missing 'url' key"

    # Verify content
    assert_match /https:\/\/tinyurl\.com\//, response_json['url']
  end

  test 'should return error JSON if URL is missing' do
    # Send a request with an empty or invalid payload
    post encode_url, params: { url: '' }, as: :json

    # Check JSON Response Structure for errors
    response_json = JSON.parse(response.body)
    assert response_json.key?('error'), "Response is missing 'error' key"
    assert_equal 'An error occurred during processing', response_json['error']
  end

  test 'should decode a valid short code and return 200 OK' do
    post_data = { alias_url: '8t3z8z8e' }

    post decode_url, params: post_data, as: :json

    # Check HTTP status code
    assert_response :ok # Status 200

    # Check JSON response content
    response_json = JSON.parse(response.body)
    assert_match /https:\/\/codesubmit\.io\//, response_json['url']
  end

  test 'should return error JSON if alias_url is invalid' do
    post_data = { alias_url: 'Non_exist' }

    post decode_url, params: post_data, as: :json

    response_json = JSON.parse(response.body)

    # Check JSON Response Structure for errors
    assert response_json.key?('error'), "Response is missing 'error' key"
    assert_equal 'An error occurred during processing', response_json['error']
  end
end
class ShortLinkController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:encode, :decode]

  def encode
    data = EncodeLinkService.new(encode_params).deliver
    render json: data
  end

  def decode
    data = DecodeLinkService.new(decode_params).deliver
    render json: data
  end

  private

  def encode_params
    params.require(:short_link).permit(:url)
  end

  def decode_params
    params.require(:short_link).permit(:alias_url)
  end
end
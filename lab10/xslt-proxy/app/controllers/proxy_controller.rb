# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'

class ProxyController < ApplicationController
  before_action :parse_params, only: :output
  def input; end

  def output
    api_response = open("http://localhost:3000/?v1=#{@value}&format=xml")
    if @side == 'server'
      @result = xslt_transform(api_response).to_html
    elsif @side == 'client-with-xslt'
      render xml: insert_browser_xslt(api_response)
    else
      render xml: api_response
    end
  end

  private

  def parse_params
    @side = params[:side]
    @value = params[:v1]
    @value = 'false' if @value.to_s =~ /^[а-я]+$/
  end

  XSLT_SERVER_TRANSFORM = "#{Rails.root}/public/server_transform.xslt"

  def xslt_transform(data, transform: XSLT_SERVER_TRANSFORM)
    doc = Nokogiri::XML(data)
    xslt = Nokogiri::XSLT(File.read(transform))
    xslt.transform(doc)
  end

  def insert_browser_xslt(data)
    data.string.sub('?>',
                    '?><?xml-stylesheet type="text/xsl" href="/browser_transform.xslt"?>')
  end
end

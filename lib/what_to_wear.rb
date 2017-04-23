require "yaml"

require "http"
require "addressable/uri"
require "verbose_hash_fetch"
require "raven"
require "sinatra"
require "rubygems"
require "bundler/setup"
require "twilio-ruby"

require "weather"
require "twilio"

module WhatToWear

  get '/' do
  	erb :index
  end

  post '/senttext' do
  	"Sending weather to: #{params['phone_number']}!"
  	phone_number = params['phone_number']
  	good_phone_number = phone_number.gsub(/\D/,"")
  	if good_phone_number.size != 10
  		erb :index
  	else
  		Twilio.send_text(phone_number)
  		"Texting #{phone_number}..."
  	end
  end

end

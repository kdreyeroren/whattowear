require "twilio-ruby"

module Twilio

  def send_text(phone_number)
    account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
    auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")

    @client = Twilio::REST::Client.new account_sid, auth_token

    @client.account.messages.create({
    	:to => "+17812234090",
    	:from => "+18575760930",
    	:body => "#{Weather.relevant_weather}",
    })
  end

end

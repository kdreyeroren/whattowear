require "yaml"

require "http"
require "addressable/uri"
require "verbose_hash_fetch"
require "raven"

API_KEY = ENV.fetch("WEATHER_API_KEY")
BASE_URI = ENV.fetch("WEATHER_BASE_URI")
WEATHER_ID = ENV.fetch("NY_WEATHER_ID")

module Weather

  def self.relevant_weather
    "Today's weather: #{precipitation}\n#{any_precip_today}\n#{current_temperature}\n#{avg_temp}\n#{highest_temp_today}\n#{humidity}"
  end

  def self.precipitation
    precip = forecast.first.dig("weather").first.dig("id")
    case
    when precip > 199 && precip < 299
      "Currently: Thunderstorm"
    when precip > 299 && precip < 399
      "Currently: Drizzle"
    when precip > 499 && precip < 599
      "Currently: Rain"
    when precip > 599 && precip < 699
      "Currently: Snow"
    when precip > 699 && precip < 899
      "Currently: No precipitation"
    when precip > 899 && precip < 907
      "Currently: Shit is cray; check the weather"
    when precip > 950 && precip < 957
      "Currently: No precipitation"
    when precip > 958
      "Shit is cray; check the weather"
    end
  end

  def self.any_precip_today
    today = forecast[2..8]
    todays_precip = today.map { |hour_period| hour_period.dig("weather").first.dig("id") }
    if todays_precip.any? { |precip| ((precip > 199 && precip < 299) || (precip > 299 && precip < 399) || (precip > 499 && precip < 599)) }
      "Today: Rain"
    elsif todays_precip.any? { |precip| (precip > 599 && precip < 699) }
      "Today: Snow"
    elsif todays_precip.any? { |precip| ((precip > 899 && precip < 907) || (precip > 958)) }
      "Shit is cray, check the weather"
    else
      "Today: No precipitation"
    end
  end

  def self.current_temperature # update the 'first' bit to be the time you're sending the text message
    temp = forecast.first.dig("main").dig("temp").to_i
    "Current temp: #{temp}"
  end

  def self.avg_temp
    today = forecast[2..8]
    temps_today = today.map { |hour_period| hour_period.dig("main").dig("temp") }
    temp = (temps_today.inject(:+) / temps_today.size).to_i
    "Avg. temp: #{temp}"
  end

  def self.highest_temp_today
    today = forecast[2..8]
    max_temps_today = today.map { |hour_period| hour_period.dig("main").dig("temp_max") }
    temp = max_temps_today.max.to_i
    "Max temp today: #{temp}"
  end

  def self.humidity
    today = forecast[2..8]
    humidities_today = today.map { |hour_period| hour_period.dig("main").dig("humidity")}
    avg_humidity = humidities_today.inject(:+) / humidities_today.size
    case
    when avg_humidity < 25
      "Currently: Not that humid"
    when avg_humidity >= 25 && avg_humidity < 50
      "Currently: A little humid"
    when avg_humidity >= 50 && avg_humidity < 75
      "Currently: Fairly humid"
    when avg_humidity >= 75
      "Currently: Quite humid"
    end
  end

  def self.configure
    Raven.configure do |config|
      config.dsn = ENV["SENTRY_DSN"] if ENV["SENTRY_DSN"]
      config.excluded_exceptions = []
    end
  end

  def self.forecast
    body = request(:get, "forecast")
    body.dig("list")
  end

  def self.request(verb, path, options={})
    uri = Addressable::URI.parse(File.join(BASE_URI, path))
    # uri.query_values = { id: "5128581", appid: API_KEY }.merge(options)
    uri.query_values = [["id", WEATHER_ID], ["APPID", API_KEY], ["units", "imperial"]]

    WhatToWear.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

    response = HTTP.request(verb, uri.to_s)

    WhatToWear.logger.info "Response #{response.code}, body: #{response.body}"

    if (200..299).cover? response.code
      JSON.parse(response.to_s)
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}, data:#{data.inspect}"
    end

  end


  def self.logger
    @logger ||= build_logger
  end

  def self.build_logger
    if RACK_ENV == "test"
      FileUtils.mkdir_p(APP_ROOT.join("log"))
      Logger.new(APP_ROOT.join("log/test.log"))
    else
      Logger.new($stdout)
    end
  end

end

# first 6 array bits will be the whole day, starting at 6am

# api.openweathermap.org/data/2.5/forecast?id=5128581&appid=2c9564a95580257635ad40cf6fe204b4

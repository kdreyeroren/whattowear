RSpec.describe WhatToWear do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

end

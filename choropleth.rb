require 'uri'
require 'net/http'
require 'json'

module Choropleth
  class Geocode
    def self.parse(data)
      if data.is_a? Array
        Hash[*data.flatten]
      else
        data
      end
    end

    def self.geocode_data(data, type)
      new_data = {}
      data.each { |k, v| new_data[geocode k, type] = v }
      new_data
    end

    private
    def self.geocode(place_name, type)
      place_name = URI.escape place_name
      url = "http://mapit.mysociety.org/areas/#{place_name}?type=#{type}"
      response = Net::HTTP.get_response(URI.parse url)

      result = JSON.parse response.body
      result.values[0]['id']
    end
  end
end


require 'pp'
data = [["East Sussex", 5.2], ["West Sussex", 2.4]]
pp Choropleth::Geocode.geocode_data(data, "CTY")

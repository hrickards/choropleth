require 'uri'
require 'net/http'
require 'json'
require 'nokogiri'

module ChoroplethGenerator
  class MapIt
    # Takes an area name and type and returns an area id
    def self.get_area_id(place_name, area_type)
      place_name = URI.escape place_name
      url = "http://mapit.mysociety.org/areas/#{place_name}?type=#{area_type}"
      response = Net::HTTP.get_response URI.parse(url)

      result = JSON.parse response.body
      result.values.first['id']
    end

    # Takes an area_id and returns the raw KML for it's boundaries
    def self.get_raw_boundary_kml(area_id)
      url = "http://mapit.mysociety.org/area/#{area_id}.kml"
      response = Net::HTTP.get_response URI.parse(url)
      response.body
    end

    # Takes an area_id and returns the parsed Nokogiri tree for the polygon boundaries
    def self.get_boundary(area_id)
      result = Nokogiri.XML get_raw_boundary_kml(area_id)
      result.remove_namespaces!

      result.xpath('//Placemark').first
    end
  end
end

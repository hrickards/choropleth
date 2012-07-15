require 'uri'
require 'net/http'
require 'json'
require 'nokogiri'

class Choropleth
  # data can be a hash or an array of arrays
  attr_accessor :data, :area_type

  def initialize(data, area_type)
    @data = data
    @area_type = area_type
  end

  # Generates KML from data
  def generate_kml
    geocode_data
    kmlise_data

    output = Nokogiri::XML::Document.new
    kml = Nokogiri::XML::Node.new 'kml', output
    kml.set_attribute 'xmlns', 'http://www.opengis.net/kml/2.2'
    document = Nokogiri::XML::Node.new 'Document', output
    kml.add_child document
    @kml_data.flatten.reverse.each { |node| document.add_child node }
    output.add_child kml

    puts output.to_xml
  end

  private
  # Sets area_data to be a hash of area ids => values
  def geocode_data
    @area_data = {}
    @data.each { |area_name, value| @area_data[geocode area_name] = value }
  end

  # Takes an area_name and returns an area id
  def geocode(place_name)
    place_name = URI.escape place_name
    url = "http://mapit.mysociety.org/areas/#{place_name}?type=#{@area_type}"
    response = Net::HTTP.get_response URI.parse(url)

    result = JSON.parse response.body
    result.values.first['id']
  end

  # Sets @kml_data to be a hash of KML boundary data => KML style data
  def kmlise_data
    @kml_data = {}
    @area_data.each { |area_id, value| @kml_data[get_boundary area_id] = get_kml_style value, area_id }
  end

  # Takes an area_id and returns the KML for it's boundaries
  def get_boundary(area_id)
    url = "http://mapit.mysociety.org/area/#{area_id}.kml"
    response = Net::HTTP.get_response URI.parse(url)

    result  = Nokogiri.XML response.body
    result.remove_namespaces!

    placemark = result.xpath('//Placemark').first
    placemark.xpath('//styleUrl').first.content = "#s#{area_id}"

    placemark
  end

  # Takes an area_id and value and returns the KML for it's style
  def get_kml_style(value, area_id)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Style(:id => "s#{area_id}") {
        xml.PolyStyle {
          xml.color get_color(value)
        }
        xml.LineStyle {
          xml.color get_color(value)
          xml.width 2
        }
      }
    end
    Nokogiri::XML(builder.to_xml).xpath '//Style'
  end

  # Takes a value and returns the color for it
  def get_color(value)
    '505078F0'
  end
end

choropleth = Choropleth.new({"East Sussex" => 5.4, "West Sussex" => 2.7, "Kent" => 0.1}, "CTY")
choropleth.generate_kml

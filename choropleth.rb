require 'nokogiri'
require_relative 'mapit'

class Choropleth
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

    @kml = output.to_xml
  end

  # Returns the KML
  def get_kml
    @kml
  end

  private
  # Sets area_data to be a hash of area ids => values
  def geocode_data
    @area_data = {}
    @data.each { |k, v| @area_data[MapIt.get_area_id k, @area_type] = v }
  end

  # Sets @kml_data to be a hash of KML boundary data => KML style data
  def kmlise_data
    @kml_data = {}
    @area_data.each { |k, v| @kml_data[get_boundary k] = get_kml_style v, k }
  end

  # Takes an area_id and returns the KML for it's boundaries
  def get_boundary(area_id)
    placemark = MapIt.get_boundary(area_id)
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
    # TODO Do this a better way. Maybe fit to normal distribution.
    delta = @data.values.max - @data.values.min
    color_range = 255.0

    step = color_range / delta

    change_val = "%02X" % (color_range - ((value - @data.values.min) * step)).round
    "5014#{change_val}FF"
  end
end

choropleth = Choropleth.new({"East Sussex" => 5.4, "West Sussex" => 2.7, "Kent" => 0.1}, "CTY")
choropleth.generate_kml
puts choropleth.get_kml

require 'uri'
require 'net/http'
require 'json'
require 'nokogiri'

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

    def self.get_boundaries(data)
      nodes = data.map { |k, v| get_boundary k }.flatten

      output = Nokogiri::XML::Document.new
      kml = Nokogiri::XML::Node.new 'kml', output
      kml.set_attribute 'xmlns', 'http://www.opengis.net/kml/2.2'
      document = Nokogiri::XML::Node.new 'Document', output
      kml.add_child document
      nodes.each { |node| document.add_child node }
      output.add_child kml
      output.to_xml
    end

    private
    def self.geocode(place_name, type)
      place_name = URI.escape place_name
      url = "http://mapit.mysociety.org/areas/#{place_name}?type=#{type}"
      response = Net::HTTP.get_response(URI.parse url)

      result = JSON.parse response.body
      result.values.first['id']
    end

    def self.get_boundary(area_id)
      url = "http://mapit.mysociety.org/area/#{area_id}.kml"
      response = Net::HTTP.get_response(URI.parse url)

      result = Nokogiri.XML response.body
      result.remove_namespaces!
      placemark = result.xpath('//Placemark').first
      placemark.xpath('//styleUrl').first.content = "#s#{area_id}"

      color = Nokogiri::XML::Node.new 'color', result
      color.content = '505078F0'
      width = Nokogiri::XML::Node.new 'width', result
      width.content = '2'
      line_style = Nokogiri::XML::Node.new 'LineStyle', result
      line_style.add_child width
      line_style.add_child color
      poly_style = Nokogiri::XML::Node.new 'PolyStyle', result
      poly_style.add_child color.clone
      style = Nokogiri::XML::Node.new 'Style', result
      style.add_child line_style
      style.add_child poly_style
      style.set_attribute 'id', "s#{area_id}"

      [style, placemark]
    end
  end

  class ValueMap
    def self.value_map(data)
      # TODO accont for probability distributions other than normal
      delta = data.max - data.min

      # TODO actually return the correct colors
      new_data = {}
      data.each { |x| new_data[x] = '7fff000' }
      new_data
    end
  end
end

class RandomGaussian
  def initialize(mean, stddev, rand_helper = lambda { Kernel.rand })
    @rand_helper = rand_helper
    @mean = mean
    @stddev = stddev
    @valid = false
    @next = 0
  end

  def rand
    if @valid then
      @valid = false
      return @next
    else
      @valid = true
      x, y = self.class.gaussian(@mean, @stddev, @rand_helper)
      @next = y
      return x
    end
  end

  private
  def self.gaussian(mean, stddev, rand)
    theta = 2 * Math::PI * rand.call
    rho = Math.sqrt(-2 * Math.log(1 - rand.call))
    scale = stddev * rho
    x = mean + scale * Math.cos(theta)
    y = mean + scale * Math.sin(theta)
    return x, y
  end
end

require 'pp'
#data = [["East Sussex", 5.2], ["West Sussex", 2.4]]
data = [["East Sussex", 5.2]]
#pp Choropleth::Geocode.geocode_data(data, "CTY")
#r = RandomGaussian.new(0,1)
#data = (0..99).map{|i| r.rand}
#pp Choropleth::ValueMap.value_map(data)
puts Choropleth::Geocode.get_boundaries(Choropleth::Geocode.geocode_data(data, "CTY"))

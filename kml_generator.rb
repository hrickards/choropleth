require 'nokogiri'

class KMLGenerator
  # Takes nodes that go under Document in the KML, and returns a full KML document
  def self.generate_from_nodes(nodes)
    output = Nokogiri::XML::Document.new

    kml = Nokogiri::XML::Node.new 'kml', output
    kml.set_attribute 'xmlns', 'http://www.opengis.net/kml/2.2'
    output.add_child kml

    document = Nokogiri::XML::Node.new 'Document', output
    kml.add_child document

    nodes.each { |node| document.add_child node }

    output.to_xml
  end

  # Takes a line_color, line_width, poly_color and style_id and returns a KML Style fragment
  def self.generate_style(line_color, line_width, poly_color, style_id)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Style(:id => style_id) {
        xml.PolyStyle {
          xml.color poly_color
        }
        xml.LineStyle {
          xml.color line_color
          xml.width line_width
        }
      }
    end
    Nokogiri::XML(builder.to_xml).xpath '//Style'
  end
end

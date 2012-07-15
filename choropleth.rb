require 'sinatra'
require 'haml'
require 'csv'
require 'cgi'
require_relative 'lib/choropleth.rb'

enable :sessions

get '/' do
  haml :index
end

post '/' do
  file = params['file'][:tempfile].read
  session[:csv] = file

  csv = CSV.parse file
  @first_row = csv.first

  haml :uploaded
end

post '/choose_location' do
  session[:value] = params['value']
  session[:location] = params['location']

  haml :choose_location
end

post '/show_map' do
  csv = CSV.parse session[:csv]
  csv.shift
  csv = csv.collect { |arr| [arr[0], arr[1].to_f] }
  data = Hash[*csv.flatten]
  choropleth = ChoroplethGenerator::Choropleth.new data, params['area_type']
  choropleth.generate_kml
  @gmaps_url = choropleth.get_gmaps_url

  haml :show_map
end

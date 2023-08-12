require 'date'
require 'json'
require 'set'
require 'yaml'

class MinMax
  def initialize
    @min = 1000
    @max = -1000
  end

  def minmax(speed)
    @max = [@max, speed].max
    @min = [@min, speed].min
  end

  def to_json(opts)
    {min: @min.round, max: @max.round}.to_json
  end
end

class Weather
  attr_reader :date

  def initialize(date)
    @date = date
    @temp= MinMax.new
    @wind = MinMax.new
    @rain = 0
    @symbols = Set.new
  end

  def temp(temp)
    @temp.minmax(temp)
  end

  def wind(wind)
    @wind.minmax(wind)
  end

  def rain(rain = 0)
    return unless rain
    @rain = [@rain, rain].max
  end

  def symbol(symbol)
    return unless symbol
    @symbols.add(symbol)
  end

  def to_json(opts)
    {date: @date.strftime('%A %d. %b'), temp: @temp, wind: @wind, rain: @rain, symbols: @symbols.to_a}.to_json
  end
end

class Place
  def initialize(name)
    @name = name
    @weather = []
  end

  def get(date)
    weather = @weather.select {|w| w.date == date}.first
    return weather if weather
    @weather << Weather.new(date)
    @weather.last
  end

  def to_json(opts)
    {name: @name, dates: @weather}.to_json
  end
end

def get_from_yr(place)
  p "Getting data for #{place['name']}"
  data = JSON.load_file('11.08.23.json')
end

def parse_response(place, data)
  p "Parsing response for #{place['name']}"
  place = Place.new(place['name'])

  timeseries = data.dig('properties', 'timeseries')
  timeseries.each do |timeserie|
    time = Date.parse(timeserie['time'])
    data = timeserie['data']
    details = data.dig('instant', 'details')

    weather = place.get(time)
    weather.wind(details['wind_speed'])
    weather.temp(details['air_temperature'])
    weather.rain(dataE.dig('next_1_hours', 'details', 'precipitation_amount'))
    weather.rain(data.dig('next_6_hours', 'details', 'precipitation_amount'))
    weather.symbol(data.dig('next_12_hours', 'summary', 'symbol_code'))
    weather.symbol(data.dig('next_1_hours', 'summary', 'symbol_code'))
    weather.symbol(data.dig('next_6_hours', 'summary', 'symbol_code'))
  end

  place
end

weather = []
places = YAML.load_file('_data/places.yaml')

places.each do |place|
  resp = get_from_yr(place)
  parsed = parse_response(place, resp)
  weather << parsed
end

File.open('_data/weather.json', 'w') do |file|
  JSON.dump(weather, file)
end

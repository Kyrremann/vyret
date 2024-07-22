require 'date'
require 'i18n'
require 'json'
require 'nokogiri'
require 'yaml'
require 'open-uri'

I18n.available_locales = [:en]

class Temp
  def initialize(tag)
    max(tag)
    min(tag)
  end

  def max(tag)
    temp = tag.css('.min-max-temperature__max')
    @max = temp.children[0].content
    @max_warm = temp.at_css('.temperature--warm-primary') ? true : false
  end

  def min(tag)
    temp = tag.css('.min-max-temperature__min')
    @min = temp.children[0].content
    @min_warm = temp.at_css('.temperature--warm-primary') ? true : false
  end

  def to_json(_state)
    { max: { temp: @max, is_warm: @max_warm }, min: { temp: @min, is_warm: @min_warm } }.to_json
  end
end

class Row
  def initialize(tr)
    @date = tr.children[0].content
    @notifications = Row.get_img_src(tr.at('warning-icon-image'))
    weather_img = tr.css('.weather-symbol__img')
    @weather_symbol_00 = Row.get_img_src(weather_img[0])
    @weather_symbol_06 = Row.get_img_src(weather_img[1])
    @weather_symbol_12 = Row.get_img_src(weather_img[2])
    @weather_symbol_18 = Row.get_img_src(weather_img[3])
    @temp = Temp.new(tr.css('.daily-weather-list-item__temperature'))
    @rain = tr.css('.daily-weather-list-item__precipitation').children[0].children[0].children[1].content
    @wind = tr.css('.wind__value').children[0].content
  end

  def self.get_img_src(img)
    return '' if img.nil?

    { src: img.attr('src').split('/').last.sub('png', 'svg'), alt: img.attr('alt') }
  end

  def to_json(_state)
    {
      date: @date,
      notifications: @notifications,
      weather_symbol_00: @weather_symbol_00,
      weather_symbol_06: @weather_symbol_06,
      weather_symbol_12: @weather_symbol_12,
      weather_symbol_18: @weather_symbol_18,
      temp: @temp,
      rain: @rain,
      wind: @wind
    }.to_json
  end
end

def parse_doc(doc)
  trs = doc.xpath('//tbody//tr')
  rows = []
  trs.each do |tr|
    rows << Row.new(tr)
  end

  rows
end

def normalize(name)
  I18n.transliterate(name.downcase).gsub(' ', '-')
end

places = YAML.load_file('_data/places.yaml')
weather = []

places.each do |place|
  p "Getting data for #{place['name']}"

  uri = "https://www.yr.no/nb/v%C3%A6rvarsel/daglig-tabell/#{place['id']}"
  doc = Nokogiri::HTML5.parse(URI.open(uri))

  dates = []
  doc.search('.daily-weather-list-item').each do |node|
    dates << Row.new(node)
  end

  weather << { name: place['name'], id: place['id'], dates: }

  File.open('_data/weather.json', 'w') do |file|
    file.puts({ updated_at: DateTime.now, weather: }.to_json)
  end
end

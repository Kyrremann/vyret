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
    @date = tr.search('time').children[0].content
    @notifications = []
    desktop_warnings = tr.css('.daily-weather-list-item__warnings-desktop') # ('.warning-icon-image') # search('.warnings-icon-group__icon')
    if desktop_warnings.any?
      desktop_warnings.css('.warning-icon-image').each do |node|
        @notifications << Row.get_img_src(node)
      end
    end
    @weather_symbol_00 = Row.get_img_src(tr.at('.daily-weather-list-item__symbol-0').at('.weather-symbol__img'))
    @weather_symbol_06 = Row.get_img_src(tr.at('.daily-weather-list-item__symbol-1').at('.weather-symbol__img'))
    @weather_symbol_12 = Row.get_img_src(tr.at('.daily-weather-list-item__symbol-2').at('.weather-symbol__img'))
    @weather_symbol_18 = Row.get_img_src(tr.at('.daily-weather-list-item__symbol-3').at('.weather-symbol__img'))
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

places = YAML.load_file('_data/places.yaml')
weather = []

places.each do |place|
  retries = 5
  p "Getting data for #{place['name']}"

  uri = "https://www.yr.no/nb/v%C3%A6rvarsel/daglig-tabell/#{place['id']}"
  begin
    site = URI.open(uri)
  rescue RuntimeError => e
    p "Error: #{e}"
    retry if (retries -= 1) > 0
  end

  doc = Nokogiri::HTML5.parse(site)

  dates = []
  doc.search('.daily-weather-list-item').each do |node|
    dates << Row.new(node)
  end

  weather << { name: place['name'], id: place['id'], dates: }

  File.open('_data/weather.json', 'w') do |file|
    file.puts({ updated_at: DateTime.now, weather: }.to_json)
  end
end

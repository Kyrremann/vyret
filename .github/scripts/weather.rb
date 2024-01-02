require 'date'
require 'i18n'
require 'json'
require 'nokogiri'
require 'yaml'
require 'open-uri'

I18n.available_locales = [:en]

class Temp
  def initialize(tag)
    self.max(tag[0])
    self.min(tag[1])
  end

  def max(tag)
    @max = tag.content
    @max_warm = tag.attr('data-is-warm')
  end

  def min(tag)
    @min = tag.content
    @min_warm = tag.attr('data-is-warm')
  end

  def to_json(state)
    {max: {temp: @max, is_warm: @max_warm}, min: {temp: @min, is_warm: @min_warm}}.to_json
  end
end

class Row
  def initialize(tr)
    @date = tr.children[0].content
    @notifications = Row.get_img_src(tr.at('.notifications'))
    @weather_symbol_00 = Row.get_img_src(tr.children[2])
    @weather_symbol_12 = Row.get_img_src(tr.children[3])
    @temp = Temp.new(tr.css('.temperature'))
    @rain = tr.children[5].content
    @wind = tr.children[6].content
  end

  def self.get_img_src(td)
    img = td.at('img')
    return "" unless img
    { src: img['src'].split('/').last.sub('png', 'svg'), alt: img['alt'] }
  end

  def to_json(state)
    {
      date: @date,
      notifications: @notifications,
      weather_symbol_00: @weather_symbol_00,
      weather_symbol_12: @weather_symbol_12,
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

  doc = Nokogiri::HTML5.parse(URI.open("https://www.yr.no/nb/innhold/#{place['id']}/table.html"))
  doc.traverse { |node| node.remove if node.text? && node.text !~ /\S/ }

  dates = parse_doc(doc)
  weather << { name: place['name'], id: place['id'], dates: dates }

  File.open('_data/weather.json', 'w') do |file|
    file.puts({updated_at: DateTime.now, weather: weather }.to_json)
  end
end

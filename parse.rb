require "i18n"
require 'nokogiri'
require 'yaml'

I18n.available_locales = [:en]

def parse(place, doc)
  table = doc.at_css('.table-container')
  imgs = table.xpath('//img')
  imgs.each do |img|
    img['src'] = 'assets/img/' + img['src'].split('/').last
  end

  table.traverse { |node| node.remove if node.text? && node.text !~ /\S/ }

  table
end

def normalize(name)
  I18n.transliterate(name.downcase)
end

places = YAML.load_file('_data/places.yaml')

places.each do |place|
  p "Getting data for #{place['name']}"
  doc = Nokogiri::HTML5.get("https://www.yr.no/nb/innhold/#{place['id']}/table.html")
  table = parse(place, doc)

  filename = normalize(place['name'])
  File.open('_includes/' + filename + '.html', 'w') do |file|
    file.puts table.to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_HTML)
  end
end

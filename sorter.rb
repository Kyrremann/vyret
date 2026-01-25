require 'json'
require 'date'

MONTHS = {
  'januar' => 1,
  'februar' => 2,
  'mars' => 3,
  'april' => 4,
  'mai' => 5,
  'juni' => 6,
  'juli' => 7,
  'august' => 8,
  'september' => 9,
  'oktober' => 10,
  'november' => 11,
  'desember' => 12
}

def clean!(data)
  data['rain'] = data['rain'].split(' ').first
  data['wind'] = data['wind'].split('/').first # We are removing the gusts

  if data['temp']
    if data['temp'].is_a?(String)
      data['temp'] =
        { 'max' => { 'temp' => data['temp'].split('/').first.sub('°', ''), 'is_warm' => false },
          'min' => { 'temp' => data['temp'].split('/').last.sub('°', ''), 'is_warm' => false } }

      data['temp']['max']['is_warm'] = true if data['temp']['max']['temp'] > '0'

      data['temp']['min']['is_warm'] = true if data['temp']['min']['temp'] > '0'
    end

    data['temp']['max']['temp'] = data['temp']['max']['temp'].sub('°', '')
    data['temp']['min']['temp'] = data['temp']['min']['temp'].sub('°', '')
  end

  data['notifications'] = [] if data['notifications'] == ''

  return unless data['notifications'].is_a?(Hash)

  data['notifications'] = [data['notifications']]
end

def parse_date(input, year)
  parts = input.split(' ')
  parts[2] = parts[2].split('Ventes').first
  month = MONTHS[parts[2].downcase]
  DateTime.parse("#{year}.#{month}.#{parts[1]}")
end

forecasts = {}

rev_list = `git rev-list main _data/weather.json`
rev_list.split("\n").each do |rev|
  begin
    weather = JSON.parse(`git show #{rev}:_data/weather.json`)
  rescue JSON::ParserError => e
    p e
    next
  end

  if weather.is_a?(Array)
    p "Rev #{rev} is array, probably old format"
    next
  end

  updated_at = DateTime.parse(weather['updated_at'])

  p "Updated at #{weather['updated_at']}"
  p updated_at

  weather['weather'].each do |forecast|
    place = forecast['name']
    next if place != 'Gygrestolen'

    forecasts[place] ||= { 'dates' => [] }

    forecast['dates'].each do |day|
      begin
        current = parse_date(day['date'], updated_at.year)
      rescue Date::Error
        p "Error parsing date: #{day['date']}"
        exit
      end

      day['date'] += " #{updated_at.year}"
      clean!(day)
      day['updated_at'] = updated_at
      forecasts[place]['dates'] << day
    end
  end
end

# Sort forecasts on updated_at for each place
forecasts.each do |place, data|
  data['dates'].sort_by! { |day| day['updated_at'] }.reverse!
end

forecasts.each do |place, data|
  File.open("_data/#{place}.json", 'w') do |file|
    file.puts({ name: place, updated_at: DateTime.now, dates: data['dates'] }.to_json)
  end
end

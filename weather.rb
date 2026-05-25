require 'date'
require 'json'
require 'yaml'
require 'open-uri'

DAYS_NB = %w[Søndag Mandag Tirsdag Onsdag Torsdag Fredag Lørdag].freeze
MONTHS_NB = %w[jan feb mar apr mai jun jul aug sep okt nov des].freeze

SEVERITY_MAP = {
  'Moderate' => 'yellow',
  'Severe' => 'orange',
  'Extreme' => 'red'
}.freeze

def format_date_nb(iso_string)
  date = Date.parse(iso_string)
  return 'I dag' if date == Date.today

  day = DAYS_NB[date.wday]
  month = MONTHS_NB[date.month - 1]
  "#{day} #{date.day}. #{month}"
end

def event_type_to_icon_name(event_type)
  # Convert camelCase to lowercase: ForestFire → forestfire, Wind → wind, etc.
  event_type.gsub(/([a-z])([A-Z])/, '\1\2').downcase
end

def fetch_json(url, retries: 5)
  begin
    JSON.parse(URI.open(url, 'User-Agent' => 'vyret/1.0 github.com/kyrremann/vyret').read)
  rescue => e
    p "Error fetching #{url}: #{e}"
    retry if (retries -= 1) > 0
    nil
  end
end

def symbol_entry(code)
  return {} if code.nil?

  { src: "#{code}.svg", alt: code }
end

def warnings_for_day(warnings, day_date)
  warnings.filter_map do |w|
    meta = w['meta'] || {}
    onset_raw = meta['onset']
    expires_raw = meta['expires']
    next unless onset_raw && expires_raw

    begin
      onset = Date.parse(onset_raw)
      expires = Date.parse(expires_raw)
    rescue Date::Error
      next
    end

    next unless day_date >= onset && day_date < expires

    severity = meta['severity']
    icon_severity = SEVERITY_MAP[severity]
    next unless icon_severity

    event_type_raw = meta['eventType']
    next unless event_type_raw

    event_type = event_type_to_icon_name(event_type_raw)
    src = "icon-warning-#{event_type}-#{icon_severity}.svg"
    alt = meta['shortTitle'] || event_type

    { src: src, alt: alt }
  end
end

places = YAML.load_file('_data/places.yaml')
weather = []

existing_weather = {}
if File.exist?('_data/weather.json')
  existing = JSON.parse(File.read('_data/weather.json'))
  existing['weather']&.each do |place|
    existing_weather[place['id']] = place
  end
end

places.each do |place|
  p "Getting data for #{place['name']}"

  forecast = fetch_json("https://www.yr.no/api/v0/locations/#{place['id']}/forecast")
  next unless forecast

  warnings_data = fetch_json("https://www.yr.no/api/v0/locations/#{place['id']}/warnings")
  warnings = warnings_data&.dig('warnings') || []

  dates = forecast['dayIntervals'].map do |interval|
    day_date = Date.parse(interval['start'])
    six_hour = interval['sixHourSymbols'] || []

    temp_max = interval.dig('temperature', 'max')&.round
    temp_min = interval.dig('temperature', 'min')&.round
    rain = interval.dig('precipitation', 'value')
    wind = interval.dig('wind', 'max')&.round

    {
      date: format_date_nb(interval['start']),
      notifications: warnings_for_day(warnings, day_date),
      weather_symbol_00: symbol_entry(six_hour[0]),
      weather_symbol_06: symbol_entry(six_hour[1]),
      weather_symbol_12: symbol_entry(six_hour[2]),
      weather_symbol_18: symbol_entry(six_hour[3]),
      temp: {
        max: { temp: temp_max, is_warm: temp_max && temp_max >= 0 },
        min: { temp: temp_min, is_warm: temp_min && temp_min >= 0 }
      },
      rain: rain,
      wind: wind
    }
  end

  # Build rolling history: old history + previous "I dag" (first entry of last run), keep 5
  old_place = existing_weather[place['id']]
  old_history = old_place ? (old_place['history'] || []) : []
  old_today = old_place ? Array(old_place['dates']).first : nil
  history = (old_history + [old_today].compact).last(5)

  weather << { name: place['name'], id: place['id'], history: history, dates: dates }

  File.open('_data/weather.json', 'w') do |file|
    file.puts({ updated_at: DateTime.now, weather: weather }.to_json)
  end
end

# Vyret

A simple weather forecast "service" listing the weather in popular areas with multi-pitches in Norway.
Updated every day at 6:00, 12:00, 16:00, and 20:00.

## Contribute

First find a spot at Yr.no, for example [Uskedalen](https://www.yr.no/nb/v%C3%A6rvarsel/daglig-tabell/1-65213/Norge/Vestland/Kvinnherad/Uskedalen).

```
https://www.yr.no/nb/v%C3%A6rvarsel/daglig-tabell/1-65213/Norge/Vestland/Kvinnherad/Uskedalen
```

Then extract the ID (in the example above it is `1-65213`) from the URL and add it to `_data/places` like this:

```yaml
- name: Uskedalen
  id: 1-65213
```

## Credits

Weather symbols from [nrkno.github.io](https://nrkno.github.io/yr-weather-symbols/).

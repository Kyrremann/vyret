---
layout: yr
---

{% assign places = site.data.weather.weather | sort: 'name' %}
{% for place in places %}
{% include weather_table.html %}
{% endfor %}

---
layout: yr
---

{% for place in site.data.weather.weather %}
{% include weather_table.html %}
{% endfor %}

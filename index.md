---
layout: yr
title: Home
---

{% for place in site.data.weather.weather %}
{% include weather_table.html %}
{% endfor %}

<a target="_blank" href="https://icons8.com/icon/6vvNkta8tr68/alps">alpine</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>

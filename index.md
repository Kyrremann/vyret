---
layout: yr
title: Home
---


{% assign places = site.data.places | sort: "name" %}
{% for place in places %}
<h1 class="location-name">{{ place.name }}</h1>
{%
    assign filename = place.name |
    downcase |
    replace: "æ", "ae" |
    replace: "å", "aa" |
    replace: "ø", "oe" |
    replace: " ", "-"
%}
{% include {{ filename  }}.html %}
{% endfor %}

<a target="_blank" href="https://icons8.com/icon/6vvNkta8tr68/alps">alpine</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>

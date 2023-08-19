---
layout: yr
---

<h2 class="location-name">
  Sammenligning
</h2>
<div class="table-container">
  <table class="table">
    <caption class="nrk-sr">Værvarsel for neste 8 dager</caption>
    <thead class="table__head">
      <tr>
        <th data-align="left"><span class="nrk-sr">Dato</span></th>
        {% for place in site.data.weather.weather %}
        <th data-align="right">{{ place.name }}</th>
        {% endfor %}
      </tr>
    </thead>
    <tbody class="table__body">
    {% assign numberOfPlaces = site.data.weather.weather | size %}
    {% assign dates = site.data.weather.weather.first.dates | map: "date" %}
    {% for date in dates %}
    {% assign index = forloop.index0 %}
      <tr>
        <th data-align="left">{{ date }}</th>
        {% for place in site.data.weather.weather %}
        {% assign day = place.dates[index] %}
        <td data-align="right">
            <span class="max-min-temperature">
                <span class="temperature" data-is-warm="{{ day.temp.max.is_warm }}">{{ day.temp.max.temp }}</span>
                <span class="max-min-temperature__separator">/</span>
                <span class="temperature" data-is-warm="{{ day.temp.min.is_warm }}">{{ day.temp.min.temp }}</span>
            </span>
        </td>
        {% endfor %}
      </tr>
      {% endfor %}
    </tbody>
  </table>
</div>

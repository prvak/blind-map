Find cities by population at https://query.wikidata.org
```
#Largest cities in Czech Republic
SELECT DISTINCT ?cityLabel ?population ?longitude ?latitude WHERE {
  ?city wdt:P31/wdt:P279* wd:Q515 .
  ?city wdt:P1082 ?population .
  FILTER(?population >= 5000)
  ?city wdt:P17 wd:Q213 .
  ?city p:P625 ?coordinate .
  ?coordinate ps:P625 ?coord .
  ?coordinate psv:P625 ?coordinate_node .
  ?coordinate_node wikibase:geoLongitude ?longitude .
  ?coordinate_node wikibase:geoLatitude ?latitude .
  ​SERVICE wikibase:label {
	bd:serviceParam wikibase:language "cs" .
  }
}
ORDER BY DESC(?population)
LIMIT 10
```

In this example the `wd:Q213` is code for Czech Republic. To find specific country code, place cursor behind `wd:` and press ctrl+space and write the name of the country.
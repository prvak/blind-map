Find mountains by prominence at https://query.wikidata.org 
```
#Mountains in the Czech Republic
SELECT DISTINCT ?mountainLabel ?height ?prominence ?longitude ?latitude WHERE {
  ?mountain wdt:P31/wdt:P279* wd:Q8502 .
  ?mountain wdt:P2660 ?prominence .
  FILTER(?prominence >= 200)
  ?mountain wdt:P2044 ?height .
  ?mountain wdt:P17 wd:Q213 .
  ?mountain p:P625 ?coordinate .
  ?coordinate ps:P625 ?coord .
  ?coordinate psv:P625 ?coordinate_node .
  ?coordinate_node wikibase:geoLongitude ?longitude .
  ?coordinate_node wikibase:geoLatitude ?latitude .
  SERVICE wikibase:label {
	bd:serviceParam wikibase:language "cs" .
  }
}
ORDER BY DESC(?height)
LIMIT 50
```
 
 `wd:Q213` is Czech Republic
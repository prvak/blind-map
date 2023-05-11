Find specific river using this query in QickOSM plugin for QGIS:
```
[out:xml] [timeout:25];
{{geocodeArea:czechia}} -> .area_0;
(
node["waterway"]["name" ="Labe"](area.area_0);
way["waterway"]["name" ="Labe"](area.area_0);
);
(._;>;);
out body;
```

How to export map layers from the QGIS using atlas feature:
https://gis.stackexchange.com/questions/316273/qgis-3-4-4-create-atlas-one-geometry-per-page
https://gis.stackexchange.com/a/414647

How to make maps with transparent background:
https://gis.stackexchange.com/a/193584



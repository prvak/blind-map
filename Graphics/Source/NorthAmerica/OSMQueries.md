
# Lakes
Lake Superior
Lake Michigan
Lake Huron
Lake Erie
Lake Ontario
```
[out:xml][timeout:25];
(
  way["natural"="water"]["name"="Lake Superior"];
  relation["natural"="water"]["name"="Lake Superior"];
);
(._;>;);
out body;
```

# Rivers
```
[out:xml][timeout:25];
relation
  ["name"="Missouri River"]
  ["waterway"="river"];
(._;>;);
out body;
```

```
[out:xml][timeout:25];
relation
  ["name"="Mississippi River"]
  ["waterway"="river"];
(._;>;);
out body;
```

```
[out:xml][timeout:25];
relation
  ["name"~"Saint-Laurent",i]
  ["waterway"="river"];
(._;>;);
out body;
```

Mackenzie River
```
[out:xml][timeout:25];
relation
  ["name"~"Deh-Cho",i]
  ["waterway"="river"];
(._;>;);
out body;
```

Rio Grande
```
[out:xml][timeout:25];
relation
  ["name"~"Rio Grande",i]
  ["waterway"="river"];
(._;>;);
out body;
```


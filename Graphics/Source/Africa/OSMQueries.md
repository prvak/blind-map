
# Lakes
Lake Victoria
Lake Tanganyika
Lake Malawi
Lake Chad
```
[out:xml][timeout:25];
relation
  ["type"="multipolygon"]
  ["water"="lake"]
  ["name"~"Lake Tanganyika"];
(._;>;);
out body;
```

# Rivers
Nile River
```
[out:xml][timeout:25];
relation
  ["name:en"="Nile River"]
  ["waterway"="river"];
(._;>;);
out body;
```
Congo
Zambezi
Orange River
Niger
```
[out:xml][timeout:25];
relation
  ["type"="waterway"]
  ["waterway"="river"]
  ["name"="Congo"];
(._;>;);
out body;
```


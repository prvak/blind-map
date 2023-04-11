1. Create map and mark its resolution in pixels (`-c`).
2. Find latitude and longitude of lower left corner (`-a`) and upper right corner (`-b`).
3. Prepare csv file with header and with `latitude` and `longitude` columns.
```
name;latitude;longitude
Praha;50.0875;14.4213
Brno;49.1952;16.6083
Ostrava;49.8355;18.2925
...
```
4. Run following script to produce pixel coordinates in the map file.
```shell
cd Scripts && python3 coordinates-to-xy.py -a "48.5518164,12.0907253" -b "51.0558422,18.8592100" -c "1882,1080" --separator ';' -f cities.csv
```

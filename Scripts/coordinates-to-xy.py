import argparse


def parseArgs():
    parser = argparse.ArgumentParser(description="Compute x, y coordinates from longitude and latitude.")
    parser.add_argument("-f", "--file", type=str, required=True,
                        help="CSV file with longitude and latitude columns.")
    parser.add_argument("-a", "--bottom-left", type=str, required=True,
                        help="(Lat,Lon) coordinates of the bottom left corner of the map image (eg. '48.5518164,12.0907253').")
    parser.add_argument("-b", "--upper-right", type=str, required=True,
                        help="(Lat,Lon) coordinates of the upper right corner of the map image (eg. '51.0558422,18.8592100').")
    parser.add_argument("-c", "--image-size", type=str, required=True,
                        help="(width,height) size of the image (eg. '1882,1080').")
    parser.add_argument("-s", "--separator", type=str, default=";",
                        help="CSV file separator. Default is ';'.")
    parser.add_argument("--lat-column", type=str, default="latitude",
                        help="Latitude column name must include this string.")
    parser.add_argument("--lon-column", type=str, default="longitude",
                        help="Latitude column name must include this string.")
    return parser.parse_args()

def coordinates_to_xy(latitude, longitude, bottom_left, upper_right, image_size):
    min_latitude = bottom_left[0]
    min_longitude = bottom_left[1]
    max_latitude = upper_right[0]
    max_longitude = upper_right[1]
    
    map_width_coord = max_longitude - min_longitude
    map_height_coord = max_latitude - min_latitude

    map_width_px = image_size[0]
    map_height_px = image_size[1]
    longitude_per_pixel = map_width_coord / map_width_px
    latitude_per_pixel = map_height_coord / map_height_px
    longitude_offset = (longitude - min_longitude)
    latitude_offset = (latitude - min_latitude)
    x = longitude_offset / longitude_per_pixel
    y = latitude_offset / latitude_per_pixel
    return x, y

args = parseArgs()
if args.file:
    with open(args.file) as f:
        lines = f.readlines()
    if len(lines) > 0:
        headers = lines[0].strip().split(args.separator)
        lines = lines[1:]
        lat_column = list(filter(lambda h: args.lat_column in h, headers))[0]
        lon_column = list(filter(lambda h: args.lon_column in h, headers))[0]
        lat_column_index = headers.index(lat_column)
        lon_column_index = headers.index(lon_column)
        if 'x' not in headers:
            headers.append('x')
            lines = [line.strip() + ";0" for line in lines]
        if 'y' not in headers:
            headers.append('y')
            lines = [line.strip() + ";0" for line in lines]
        x_column_index = headers.index("x")
        y_column_index = headers.index("y")

        a = tuple(float(coord) for coord in args.bottom_left.split(","))
        b = tuple(float(coord) for coord in args.upper_right.split(","))
        c = tuple(int(coord) for coord in args.image_size.split(","))
        print(";".join(headers))
        for line in lines:
            line = line.strip()
            parts = line.split(args.separator)
            lat = float(parts[lat_column_index])
            lon = float(parts[lon_column_index])
            (x, y) = coordinates_to_xy(lat, lon, a, b, c)
            parts[x_column_index] = str(int(x))
            parts[y_column_index] = str(int(y))
            print(";".join(parts))

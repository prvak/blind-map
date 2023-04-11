import argparse
import os.path as ospath
from PIL import Image


def parse_args():
    parser = argparse.ArgumentParser(description="Compute x, y coordinates from non-transparent images.")
    parser.add_argument("-c", "--image-size", type=str, required=True,
                        help="(width,height) size of the image (eg. '1920,1080').")
    parser.add_argument("-s", "--separator", type=str, default=";",
                        help="CSV file separator. Default is ';'.")
    parser.add_argument("FILE", type=str, nargs="+",
                        help="Image file.")
    return parser.parse_args()


args = parse_args()
print(args.separator.join(["name", "x", "y"]))
for image_path in args.FILE:
    name = ospath.splitext(ospath.basename(image_path))[0]
    image = Image.open(image_path)
    expected_size = tuple(int(coord) for coord in args.image_size.split(","))
    image_size = image.size
    if image_size != expected_size:
        raise Exception("Size {} of '{}' does not match the expected size {}"
                        .format(image_size, image_path, expected_size))
    active_box = image.getbbox()
    box_x = active_box[0]
    box_y = active_box[1]
    box_width = active_box[2] - box_x
    box_height = active_box[3] - box_y
    x = box_x + box_width / 2
    y = image_size[1] - box_y - box_height / 2
    result = args.separator.join([name, str(x), str(y)])
    print(result)

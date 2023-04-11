#!/bin/python3
import glob
import argparse
import math
import os.path as ospath
import os as os
import subprocess
import shutil
from PIL import Image
import re
import yaml

RENDER_FILE_EXTENSION = ".render.yaml"
SCRIPT_DIR = ospath.dirname(ospath.realpath(__file__))
GODOT_DIR = ospath.join(SCRIPT_DIR, "..", "BlindMap")
GRAPHICS_DIR = ospath.join(SCRIPT_DIR, "..", "Graphics")
ASSETS_DIR = "."


def checkFile(value):
    if type(value) != type(""):
        raise argparse.ArgumentTypeError("'{}' is not a string.".format(value))
    if not value.endswith(RENDER_FILE_EXTENSION):
        raise argparse.ArgumentTypeError("'{}' does not end with '{}' extension.".format(value, RENDER_FILE_EXTENSION))
    if not ospath.exists(value):
        raise argparse.ArgumentTypeError("'{}' does not exist.".format(value))
    if not ospath.isfile(value):
        raise argparse.ArgumentTypeError("'{}' is not a file.".format(value))
    return value

def checkDir(value):
    if type(value) != type(""):
        raise argparse.ArgumentTypeError("'{}' is not a string.".format(value))
    if not ospath.exists(value):
        raise argparse.ArgumentTypeError("'{}' does not exist.".format(value))
    if not ospath.isdir(value):
        raise argparse.ArgumentTypeError("'{}' is not a directory.".format(value))
    if not value.endswith(ospath.sep):
        return value + ospath.sep
    return value

def parseArgs():
    parser = argparse.ArgumentParser(description="Automatically process Synfig Studio files (*.sif), Krita (*.kra) files and more to png files based on instructions in *.render.yaml files.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-f", "--file", type=checkFile, help="File to render.")
    group.add_argument("-d", "--dir", type=checkDir, help="Render all changed images in given directory"
                                                          "(based on source and target modification time).")
    parser.add_argument("--force", default=False, action="store_true")
    return parser.parse_args()

def alignOrDefault(config):
    if "align" in config:
        return {
            "horizontal": config["align"]["horizontal"],
            "vertical": config["align"]["vertical"],
        }
    else:
        return {
            "horizontal": "none",
            "vertical": "none",
        }

def parseRenderData(renderDataPath):
    with open(renderDataPath, "r") as f:
        config = yaml.safe_load(f)
        type = config["type"]
        baseName = ospath.basename(renderDataPath[0:-len(RENDER_FILE_EXTENSION)])
        if "sourceFile" in config:
            # Use source file from the config.
            sourceFile = ospath.join(ospath.dirname(renderDataPath), config["sourceFile"])
        else:
            # Use same source file as config file name.
            sourceFile = ospath.join(ospath.dirname(renderDataPath), baseName) + ".sif"
            if not ospath.exists(sourceFile):
                sourceFile = ospath.join(ospath.dirname(renderDataPath), baseName) + ".kra"
            if not ospath.exists(sourceFile):
                sourceFile = ospath.join(ospath.dirname(renderDataPath), baseName) + ".png"
        if "sprite" in config["render"]: 
            spriteDir = config["render"]["sprite"]
        else:
            normGraphicsDir = ospath.normpath(GRAPHICS_DIR) + ospath.sep
            normSourceFileDir = ospath.normpath(ospath.join(SCRIPT_DIR, ospath.dirname(sourceFile)))
            spriteDir = normSourceFileDir.replace(normGraphicsDir, "")
            if normSourceFileDir == spriteDir:
                raise Exception(f"Source file {normSourceFileDir} is not in the graphics dir {normGraphicsDir}.")
            spriteDir = ospath.join(ASSETS_DIR, spriteDir)
        targetFile = ospath.join(GODOT_DIR, spriteDir, baseName) + ".png"

        if type == "simple":
            return {
                "type": type,
                "sourceFile": sourceFile,
                "targetFile": targetFile,
                "render": {
                    "width": config["render"]["width"],
                    "height": config["render"]["height"],
                    "sprite": spriteDir,
                },
            }
        elif type == "layers":
            return {
                "type": type,
                "sourceFile": sourceFile,
                "targetFile": targetFile,
                "render": {
                    "sprite": spriteDir,
                },
            }
        elif type == "animation":
            return {
                "type": type,
                "sourceFile": sourceFile,
                "targetFile": targetFile,
                "render": {
                    "width": config["render"]["width"],
                    "height": config["render"]["height"],
                    "columns": config["render"]["columns"],
                    "fps": config["render"]["fps"],
                    "sprite": spriteDir,
                },
                "align": alignOrDefault(config),
            }
        else:
            raise Exception("Unknown type '{}' in {}.".format(type, renderDataPath))

def cropImage(image, width, height, align):
    activeBox = image.getbbox()
    if not activeBox:
        raise ValueError("Image to crop is empty.")
    (x0, y0, x1, y1) = activeBox
    (horizontal, vertical) = align
    (sourceWidth, sourceHeight) = image.size
    if x1 - x0 > width or y1 - y0 > height:
        raise ValueError("Image to crop would loose active pixels: w={}, h={}, box={}".format(width, height, activeBox))

    x, y = 0, 0
    if horizontal == "none":
        x = int(sourceWidth / 2 - width / 2)
    elif horizontal == "center":
        x = x0 - int(sourceWidth / 2 - (x1 - x0) / 2)
    else:
        raise ValueError("Unexpected horizontal alignment: '{}'".format(horizontal))

    if vertical == "none":
        y = int(sourceHeight / 2 - height / 2)
    elif vertical == "bottom":
        y = y1 - height
    elif horizontal == "center":
        y = y0 - int(sourceHeight / 2 - (y1 - y0) / 2)
    else:
        raise ValueError("Unexpected vertical alignment: '{}'".format(vertical))
    return image.crop((x, y, x + width, y + height))

def cutImage(image, x, y, width, height, transform = None):
    result = image.crop((x, y, x + width, y + height))
    activeBox = result.getbbox()
    if not activeBox:
        raise ValueError("Subimage at coordinates 'x: {}, y: {}, {}x{}' is empty.".format(x, y, width, height))

    if transform == "flipx":
        result = result.transpose(Image.FLIP_LEFT_RIGHT)
    elif transform == "flipy":
        result = result.transpose(Image.FLIP_TOP_BOTTOM)
    return result

def determineFinalWidth(renderData, renderedImage):
    desiredWidth = renderData["render"]["width"]
    desiredHeight = renderData["render"]["height"]

    (sourceWidth, sourceHeight) = renderedImage.size
    activeBox = renderedImage.getbbox()
    if not activeBox:
        raise ValueError("Image to crop is empty.")
    (x0, y0, x1, y1) = activeBox
    activeWidth = x1 - x0
    activeHeight = y1 - y0
    if desiredWidth == "auto":
        finalWidth = sourceWidth
        x = 0
    elif desiredWidth == "crop":
        finalWidth = activeWidth
        x = x0
    else:
        finalWidth = desiredWidth
        x = (sourceWidth - desiredWidth) / 2

    if desiredHeight == "auto":
        finalHeight = sourceHeight
        y = 0
    elif desiredHeight == "crop":
        finalHeight = activeHeight
        y = y0
    else:
        finalHeight = desiredHeight
        y = (sourceHeight - desiredHeight) / 2

    return x, y, finalWidth, finalHeight

def isChanged(renderFile, renderData, baseName):
    renderFileModifiedAt = ospath.getmtime(renderFile)
    sourceFileModifiedAt = ospath.getmtime(renderData["sourceFile"])
    try:
        targetFile = renderData["targetFile"]
        if renderData["type"] == "layers":
            targetDir = ospath.dirname(targetFile)
            targetFileNames = sorted(filter(lambda f: re.match(baseName + "_.*\.png$", f) != None, os.listdir(targetDir)))
            targetFilesModifiedAt = []
            for targetFileName in targetFileNames:
                modifiedAt = ospath.getmtime(ospath.join(targetDir, targetFileName))
                targetFilesModifiedAt.append(modifiedAt)
            targetFileModifiedAt = 0 if len(targetFilesModifiedAt) == 0 else min(targetFilesModifiedAt)
        else:
            targetFileModifiedAt = ospath.getmtime(targetFile)
    except:
        targetFileModifiedAt = 0
    return targetFileModifiedAt < sourceFileModifiedAt or targetFileModifiedAt < renderFileModifiedAt

def renderSifFile(renderData, tempFile):
    with open(os.devnull, 'w') as devnull:
        result = subprocess.call(
            [
                "/bin/synfig",
                "--target", "png",
                "--quality", "10",
                "--antialias", "30",
                "--time", "0",
                "--output-file", tempFile,
                renderData["sourceFile"],
            ],
            stdout=devnull,
            stderr=subprocess.STDOUT
        )

def renderSifAnimation(renderData, tempFile):
    with open(os.devnull, 'w') as devnull:
        result = subprocess.call(
            [
                "/bin/synfig",
                "--target", "png",
                "--quality", "10",
                "--antialias", "30",
                "--fps", str(renderData["render"]["fps"]),
                "--output-file", tempFile,
                renderData["sourceFile"]
            ],
            stdout = devnull,
            stderr = subprocess.STDOUT
        )

def renderKraFile(renderData, tempFile):
    with open(os.devnull, 'w') as devnull:
        result = subprocess.call(
            [
                "/bin/krita",
                renderData["sourceFile"],
                "--export",
                "--export-filename", tempFile,
            ],
            stdout=devnull,
            stderr=subprocess.STDOUT
        )

def renderPngFile(renderData, tempFile):
    shutil.copy(renderData["sourceFile"], tempFile)

def renderSimpleImage(renderData, baseName, tempDir):
    tempFile = ospath.join(tempDir, baseName) + ".png"
    shutil.rmtree(tempDir, ignore_errors=True)
    os.makedirs(tempDir, exist_ok=True)
    if renderData["sourceFile"].endswith(".kra"):
        renderKraFile(renderData, tempFile)
    elif renderData["sourceFile"].endswith(".sif"):
        renderSifFile(renderData, tempFile)
    elif renderData["sourceFile"].endswith(".png"):
        renderPngFile(renderData, tempFile)
    else:
        raise Exception("Unexpected source file format: '{}'".format(renderData["sourceFile"]))

    spriteDir = renderData["render"]["sprite"]
    renderedImage = Image.open(ospath.join(tempDir, tempFile))
    (x, y, finalWidth, finalHeight) = determineFinalWidth(renderData, renderedImage)

    finalImage = Image.new(mode="RGBA", size=(finalWidth, finalHeight))
    cuttedImage = cutImage(renderedImage, x, y, finalWidth, finalHeight)
    finalImage.paste(cuttedImage)
    
    targetFile = ospath.join(GODOT_DIR, spriteDir, baseName) + ".png"
    previewFile = ospath.join(ospath.dirname(renderData["sourceFile"]), baseName) + ".preview.png"
    os.makedirs(ospath.dirname(targetFile), exist_ok=True)
    finalImage.save(targetFile)
    subprocess.run(["optipng", targetFile])
    shutil.copy(targetFile, previewFile)
    shutil.rmtree(tempDir)

def renderLayers(renderData, baseName, tempDir):
    tempFile = ospath.join(tempDir, baseName) + ".scml"
    shutil.rmtree(tempDir, ignore_errors=True)
    os.makedirs(tempDir, exist_ok=True)
    if renderData["sourceFile"].endswith(".kra"):
        renderKraFile(renderData, tempFile)
    else:
        raise Exception("Unexpected source file format: '{}'".format(renderData["sourceFile"]))

    renderedFiles = sorted(filter(lambda f: re.match(".*\.png", f) != None, os.listdir(tempDir)))
    spriteDir = renderData["render"]["sprite"]
    os.makedirs(ospath.join(GODOT_DIR, spriteDir), exist_ok=True)
    for index, renderedFile in enumerate(renderedFiles):
        targetFile = ospath.join(GODOT_DIR, spriteDir, baseName) + "_" + ospath.basename(renderedFile)
        shutil.copy(ospath.join(tempDir, renderedFile), targetFile)
        subprocess.run(["optipng", targetFile])

    shutil.rmtree(tempDir)

def renderAnimation(renderData, baseName, tempDir):
    tempFile = ospath.join(tempDir, baseName) + ".png"
    shutil.rmtree(tempDir, ignore_errors=True)
    os.makedirs(tempDir, exist_ok=True)

    renderSifAnimation(renderData, tempFile)
    renderedFiles = sorted(filter(lambda f: re.match(".*\.[0-9]+\.png", f) != None, os.listdir(tempDir)))
    if len(renderedFiles) == 0:
        raise Exception("No animation frames rendered from file '{}'.".format(renderData["sourceFile"]))
    columns = renderData["render"]["columns"]
    finalWidth = renderData["render"]["width"] * columns
    finalHeight = renderData["render"]["height"] * int(math.ceil(len(renderedFiles) / columns))
    spriteDir = renderData["render"]["sprite"]

    width = renderData["render"]["width"]
    height = renderData["render"]["height"]
    align = (renderData["align"]["horizontal"], renderData["align"]["vertical"])

    finalImage = Image.new(mode="RGBA", size=(finalWidth, finalHeight))
    for index, renderedFile in enumerate(renderedFiles):
        renderedImage = Image.open(ospath.join(tempDir, renderedFile))
        croppedImage = cropImage(renderedImage, width, height, align)

        x = width * (index % columns)
        y = height * (int(math.floor(index / columns)))
        finalImage.paste(croppedImage, (x, y, x + width, y + height))
    targetFile = ospath.join(GODOT_DIR, spriteDir, baseName) + ".png"
    previewFile = ospath.join(ospath.dirname(renderData["sourceFile"]), baseName) + ".preview.png"
    print("Rendering '{}'".format(ospath.join(spriteDir, baseName) + ".png"))
    os.makedirs(ospath.dirname(targetFile), exist_ok=True)
    finalImage.save(targetFile)
    subprocess.run(["optipng", targetFile])
    shutil.copy(targetFile, previewFile)
    shutil.rmtree(tempDir)

def renderFile(renderFile, onlyIfChanged = True):
    baseName = ospath.basename(renderFile[0:-len(RENDER_FILE_EXTENSION)])

    renderData = parseRenderData(renderFile)
    if onlyIfChanged and not isChanged(renderFile, renderData, baseName):
        return
    else:
        print("Rendering file '{}'.".format(renderFile))


    tempDir = ospath.join(SCRIPT_DIR, "tmp", baseName)
    if renderData["type"] == "simple":
        renderSimpleImage(renderData, baseName, tempDir)
    elif renderData["type"] == "layers":
        renderLayers(renderData, baseName, tempDir)
    elif renderData["type"] == "animation":
        renderAnimation(renderData, baseName, tempDir)
    else:
        raise ValueError("Unknown render data type " + renderData["type"])


def renderDirectory(renderDirectory, onlyIfChanged = True):
    for filename in glob.iglob(renderDirectory + '**/*' + RENDER_FILE_EXTENSION, recursive=True):
        renderFile(filename, onlyIfChanged)

args = parseArgs()
if args.file:
    renderFile(args.file, onlyIfChanged=not args.force)
elif args.dir:
    renderDirectory(args.dir, onlyIfChanged=not args.force)


# synfig -Q 10 -a 30 --fps 12 wizard1_walking_forward.sif -o tmp/w.png

#if __name__ == "__main__":

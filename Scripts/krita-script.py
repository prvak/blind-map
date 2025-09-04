# Print initial version of resource table from layers.
app = Krita.instance()
document = app.activeDocument()
nodes = document.topLevelNodes()
bounds = document.bounds()
total_w = bounds.width()
total_h = bounds.height()
print("id;name;x;y;z;sprite;name:cs;name:de")
for i, node in enumerate(filter(lambda n: n.visible(), nodes)):
    b = node.bounds()
    x = b.x() + b.width()/2
    y = total_h - b.y() - b.height()/2
    print("{};{};{};{};0;{}.png;;".format(i, node.name(), x, y, node.name()))

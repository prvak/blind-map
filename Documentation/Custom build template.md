Idea was to have smaller wasm file. Size was reduced from 28MB to 23MB but the application crashed at startup.

How to use custom build templates:
https://github.com/godotengine/godot/pull/62996

https://docs.godotengine.org/en/latest/contributing/development/compiling/compiling_for_web.html#building-export-templates

```shell
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh

git clone https://github.com/godotengine/godot.git
cd godot
4.0-stable
scons platform=web target=template_release build_profile=custom.build
```

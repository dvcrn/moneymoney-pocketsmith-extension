dist/out.lua: src/Main.hx src/Pocketsmith.hx src/Storage.hx src/JsonHelper.hx src/RequestHelper.hx
	mkdir -p dist
	cd src/ && haxe --lua ../dist/out.lua --main Main -D lua-vanilla -D lua-return

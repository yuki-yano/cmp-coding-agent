deps:
	./scripts/bootstrap_deps.sh

test: deps
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua dofile('scripts/minitest.lua')"

format:
	stylua lua tests scripts

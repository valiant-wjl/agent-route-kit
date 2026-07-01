.PHONY: render smoke clean

render:
	python3 tools/render-config.py --env agent-input.env --out build

smoke:
	bash tests/smoke.sh

clean:
	rm -rf build

XML = ../../dwl/protocols/dwl-ipc-unstable-v2.xml
SCANNER = `pkg-config --variable=wayland_scanner wayland-scanner`

dwl-bar-ipc: dwl-bar-ipc.c dwl-ipc-unstable-v2-client.h dwl-ipc-unstable-v2-client.c
	$(CC) -O2 -Wall -Wno-unused-parameter dwl-bar-ipc.c dwl-ipc-unstable-v2-client.c \
		`pkg-config --cflags --libs wayland-client` -o $@

dwl-ipc-unstable-v2-client.h: $(XML)
	$(SCANNER) client-header $(XML) $@
dwl-ipc-unstable-v2-client.c: $(XML)
	$(SCANNER) private-code $(XML) $@

clean:
	rm -f dwl-bar-ipc dwl-ipc-unstable-v2-client.h dwl-ipc-unstable-v2-client.c

.PHONY: clean

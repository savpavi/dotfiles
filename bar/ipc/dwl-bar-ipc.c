/*
 * dwl-bar-ipc: tiny dwl-ipc-unstable-v2 client for the Quickshell bar.
 *
 *   dwl-bar-ipc                     watch; one JSON line per output frame
 *   dwl-bar-ipc view OUTPUT MASK    view tag bitmask on OUTPUT
 *   dwl-bar-ipc toggle OUTPUT MASK  toggle tag bitmask in the current view
 *   dwl-bar-ipc layout OUTPUT IDX   select layout IDX on OUTPUT
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>

#include "dwl-ipc-unstable-v2-client.h"

#define MAXTAGS 32

typedef struct Out {
	struct wl_output *wl;
	struct zdwl_ipc_output_v2 *ipc;
	char *name, *title, *appid, *symbol;
	uint32_t active, fullscreen, floating;
	uint32_t state[MAXTAGS], clients[MAXTAGS], focused[MAXTAGS];
	struct Out *next;
} Out;

static struct zdwl_ipc_manager_v2 *manager;
static Out *outs;
static uint32_t ntags;
static int watching;

static void
setstr(char **dst, const char *src)
{
	free(*dst);
	*dst = strdup(src ? src : "");
}

static void
putjson(const char *s)
{
	const unsigned char *p = (const unsigned char *)(s ? s : "");
	putchar('"');
	for (; *p; p++) {
		if (*p == '"' || *p == '\\')
			printf("\\%c", *p);
		else if (*p < 0x20)
			printf("\\u%04x", *p);
		else
			putchar(*p);
	}
	putchar('"');
}

/* wl_output: only the name matters */
static void o_geometry(void *d, struct wl_output *o, int32_t x, int32_t y, int32_t pw,
	int32_t ph, int32_t sp, const char *mk, const char *md, int32_t tr) {}
static void o_mode(void *d, struct wl_output *o, uint32_t f, int32_t w, int32_t h, int32_t r) {}
static void o_done(void *d, struct wl_output *o) {}
static void o_scale(void *d, struct wl_output *o, int32_t s) {}
static void o_name(void *d, struct wl_output *o, const char *name) { setstr(&((Out *)d)->name, name); }
static void o_desc(void *d, struct wl_output *o, const char *desc) {}
static const struct wl_output_listener output_listener = {
	o_geometry, o_mode, o_done, o_scale, o_name, o_desc,
};

/* zdwl_ipc_output_v2 */
static void i_toggle_visibility(void *d, struct zdwl_ipc_output_v2 *i) {}
static void i_active(void *d, struct zdwl_ipc_output_v2 *i, uint32_t a) { ((Out *)d)->active = a; }
static void
i_tag(void *d, struct zdwl_ipc_output_v2 *i, uint32_t tag, uint32_t state,
	uint32_t clients, uint32_t focused)
{
	Out *o = d;
	if (tag >= MAXTAGS)
		return;
	o->state[tag] = state;
	o->clients[tag] = clients;
	o->focused[tag] = focused;
}
static void i_layout(void *d, struct zdwl_ipc_output_v2 *i, uint32_t l) {}
static void i_title(void *d, struct zdwl_ipc_output_v2 *i, const char *t) { setstr(&((Out *)d)->title, t); }
static void i_appid(void *d, struct zdwl_ipc_output_v2 *i, const char *a) { setstr(&((Out *)d)->appid, a); }
static void i_symbol(void *d, struct zdwl_ipc_output_v2 *i, const char *s) { setstr(&((Out *)d)->symbol, s); }
static void
i_frame(void *d, struct zdwl_ipc_output_v2 *i)
{
	Out *o = d;
	uint32_t t;

	if (!watching)
		return;
	printf("{\"output\":");
	putjson(o->name);
	printf(",\"active\":%u,\"layout\":", o->active);
	putjson(o->symbol);
	printf(",\"title\":");
	putjson(o->title);
	printf(",\"appid\":");
	putjson(o->appid);
	printf(",\"fullscreen\":%u,\"floating\":%u,\"tags\":[", o->fullscreen, o->floating);
	for (t = 0; t < ntags && t < MAXTAGS; t++)
		printf("%s{\"s\":%u,\"c\":%u,\"f\":%u}", t ? "," : "",
			o->state[t], o->clients[t], o->focused[t]);
	printf("]}\n");
	fflush(stdout);
}
static void i_fullscreen(void *d, struct zdwl_ipc_output_v2 *i, uint32_t f) { ((Out *)d)->fullscreen = f; }
static void i_floating(void *d, struct zdwl_ipc_output_v2 *i, uint32_t f) { ((Out *)d)->floating = f; }
static void i_geom(void *d, struct zdwl_ipc_output_v2 *i, int32_t x, int32_t y, int32_t w, int32_t h) {}
static const struct zdwl_ipc_output_v2_listener ipc_listener = {
	i_toggle_visibility, i_active, i_tag, i_layout, i_title, i_appid,
	i_symbol, i_frame, i_fullscreen, i_floating, i_geom,
};

/* zdwl_ipc_manager_v2 */
static void m_tags(void *d, struct zdwl_ipc_manager_v2 *m, uint32_t amount) { ntags = amount; }
static void m_layout(void *d, struct zdwl_ipc_manager_v2 *m, const char *name) {}
static const struct zdwl_ipc_manager_v2_listener manager_listener = { m_tags, m_layout };

static void
attach(Out *o)
{
	if (!manager || o->ipc)
		return;
	o->ipc = zdwl_ipc_manager_v2_get_output(manager, o->wl);
	zdwl_ipc_output_v2_add_listener(o->ipc, &ipc_listener, o);
}

static void
global(void *d, struct wl_registry *reg, uint32_t name, const char *iface, uint32_t ver)
{
	Out *o;

	if (!strcmp(iface, wl_output_interface.name) && ver >= 4) {
		o = calloc(1, sizeof(*o));
		o->wl = wl_registry_bind(reg, name, &wl_output_interface, 4);
		wl_output_add_listener(o->wl, &output_listener, o);
		o->next = outs;
		outs = o;
		attach(o);
	} else if (!strcmp(iface, zdwl_ipc_manager_v2_interface.name)) {
		manager = wl_registry_bind(reg, name, &zdwl_ipc_manager_v2_interface, ver < 2 ? ver : 2);
		zdwl_ipc_manager_v2_add_listener(manager, &manager_listener, NULL);
		for (o = outs; o; o = o->next)
			attach(o);
	}
}
static void global_remove(void *d, struct wl_registry *reg, uint32_t name) {}
static const struct wl_registry_listener registry_listener = { global, global_remove };

int
main(int argc, char *argv[])
{
	struct wl_display *dpy = wl_display_connect(NULL);
	struct wl_registry *reg;
	Out *o;
	uint32_t val;

	if (!dpy) {
		fprintf(stderr, "dwl-bar-ipc: cannot connect to wayland display\n");
		return 1;
	}
	if (argc != 1 && argc != 4) {
		fprintf(stderr, "usage: dwl-bar-ipc [view|toggle|layout OUTPUT VALUE]\n");
		return 2;
	}
	watching = argc == 1;

	reg = wl_display_get_registry(dpy);
	wl_registry_add_listener(reg, &registry_listener, NULL);
	wl_display_roundtrip(dpy);
	if (!manager) {
		fprintf(stderr, "dwl-bar-ipc: compositor has no dwl-ipc-unstable-v2\n");
		return 1;
	}
	wl_display_roundtrip(dpy);

	if (watching) {
		while (wl_display_dispatch(dpy) != -1)
			;
		return 0;
	}

	val = (uint32_t)strtoul(argv[3], NULL, 0);
	for (o = outs; o; o = o->next) {
		if (!o->ipc || !o->name || strcmp(o->name, argv[2]))
			continue;
		if (!strcmp(argv[1], "view"))
			zdwl_ipc_output_v2_set_tags(o->ipc, val, 1);
		else if (!strcmp(argv[1], "toggle")) {
			uint32_t t, cur = 0;
			for (t = 0; t < ntags && t < MAXTAGS; t++)
				if (o->state[t] & ZDWL_IPC_OUTPUT_V2_TAG_STATE_ACTIVE)
					cur |= 1u << t;
			if (cur ^ val)
				zdwl_ipc_output_v2_set_tags(o->ipc, cur ^ val, 0);
		} else if (!strcmp(argv[1], "layout"))
			zdwl_ipc_output_v2_set_layout(o->ipc, val);
		else
			return 2;
		wl_display_roundtrip(dpy);
		return 0;
	}
	fprintf(stderr, "dwl-bar-ipc: no such output: %s\n", argv[2]);
	return 1;
}

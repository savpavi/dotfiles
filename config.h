/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* Derlenmis varsayilan Murekkep; calisirken ~/.local/state/dwl-theme/dwl.conf ezer (bin/dwl-theme) */
/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static unsigned int borderpx         = 2;  /* border pixel of windows */
static unsigned int gappx                  = 0;  /* gap between and around tiled windows */
static const unsigned int snap             = 32; /* snap pixel */
static float rootcolor[]             = COLOR(0xECE6D9ff);
static float bordercolor[]           = COLOR(0x1B1A17ff);
static float focuscolor[]            = COLOR(0xD2452Dff);
static float urgentcolor[]           = COLOR(0x2B4C7Eff);
/* This conforms to the xdg-protocol. Set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f}; /* You can also use glsl colors */

/* rounded corners, shadows and blur (scenefx patch). Off here; a theme turns them on with
 * "radius", "shadow" and "blur" in dwl.conf. */
static int corner_radius                   = 0;  /* radius of the corners of window contents, 0 disables them */
static const int corner_radius_only_floating = 0; /* 1 means only floating windows have rounded corners */
static int shadow_sigma                    = 0;  /* blur sigma and size of window shadows, 0 disables them */
static const float shadow_color[]          = COLOR(0x00000090);
/* blur behind translucent windows. num_passes 0 disables it */
static struct blur_data blur_data          = { .num_passes = 0, .radius = 5, .noise = 0.02f,
                                               .brightness = 0.9f, .contrast = 0.9f, .saturation = 1.1f };

/* animation (animation patch); the theme's "anim" value overrides the duration, 0 = off */
static unsigned int animation_duration = 160; /* ms */
static const float animation_curve[4] = {0.0f, 0.85f, 0.2f, 1.0f}; /* cubic-bezier x1, y1, x2, y2 */

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

/* Autostart */
static const char *const autostart[] = {
	/* her sey bin/dwl-autostart icinde; orayi degistirmek yeniden derleme istemez */
	"/home/savpavi/Projects/dwl/bin/dwl-autostart", NULL,
	NULL /* terminate */
};

static const Rule rules[] = {
	/* app_id (buyuk/kucuk harf fark etmez, parca eslesir)   title  tags     float  ekran */
	/* ASUS XG27ACS = DP-1, LG UltraGear = DP-3 */
	{ "looking-glass-client",  NULL,  1 << 2,  0,  "DP-3",  0 },
	{ "claude",                NULL,  1 << 0,  0,  "DP-3",  0 },
	{ "telegram",              NULL,  1 << 1,  0,  "DP-3",  0 },
	{ "dev.zed",               NULL,  1 << 3,  0,  "DP-3",  0 },
	{ "discord",               NULL,  1 << 2,  0,  "DP-1",  0 },
	{ "spotify",               NULL,  1 << 1,  0,  "DP-1",  0 },
	{ "=brave-origin",         NULL,  1 << 0,  0,  "DP-1",  0 },  /* "=" tam eslesme: web app'ler (brave-origin-<site>-Default) haric */
	{ "obsidian",              NULL,  1 << 3,  0,  "DP-1",  0 },
	{ "mailcraft",             NULL,  1 << 4,  0,  "DP-1",  0 },
	/* kucuk araclar dosenmesin */
	{ "kcalc",                 NULL,  0,       1,  NULL,  0 },
	{ "calculator",            NULL,  0,       1,  NULL,  0 },
	{ "qalculate",             NULL,  0,       1,  NULL,  0 },
	{ "pavucontrol",           NULL,  0,       1,  NULL,  0 },
	{ "pwvucontrol",           NULL,  0,       1,  NULL,  0 },
	{ "solaar",                NULL,  0,       1,  NULL,  0 },
	{ "nm-connection-editor",  NULL,  0,       1,  NULL,  0 },
	{ "blueman",               NULL,  0,       1,  NULL,  0 },
	{ "zenity",                NULL,  0,       1,  NULL,  0 },
	{ "satty",                 NULL,  0,       1,  NULL,  0 },
	{ "polkit",                NULL,  0,       1,  NULL,  0 },
	{ "xdg-desktop-portal",    NULL,  0,       1,  NULL,  0 },
	{ "kdeconnect",            NULL,  0,       1,  NULL,  0 },
	{ "digup",                 NULL,  0,       1,  NULL,  1 },  /* panel: ortada, boyutunu izler, fare odagi calmaz */
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* monitors */
/* (x=-1, y=-1) is reserved as an "autoconfigure" monitor position indicator
 * WARNING: negative values other than (-1, -1) cause problems with Xwayland clients due to
 * https://gitlab.freedesktop.org/xorg/xserver/-/issues/899 */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect              x  y  resx resy rate mode adaptive*/
	/* example of a HiDPI laptop monitor at 120Hz: { "eDP-1",    0.5f,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 0, 0, 0, 0, 120.000f, 1, 1}, */
	/*
	* mode let's the user decide on how dwl should implement the modes:
	* -1 Sets a custom mode following the users choice
	* All other number's set the mode at the index n, 0 is the standard mode; see wlr-randr
	*/
	/* savpavi: mode -2 = listelenen modlardan resx x resy @ rate'e en yakini */
	{ "DP-1",     0.58f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 0,    0,   2560, 1440, 180.0f, -2, 0},
	{ "DP-3",     0.58f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 2560, 180, 1920, 1080, 120.0f, -2, 0},
	{ NULL,       0.58f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1, -1, 0, 0, 0.0f, 0 ,0},
	/* default monitor rule: can be changed but cannot be eliminated; at least one monitor rule must exist */
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
	.layout = "tr,us",
	/* iki Shift birlikte: tr <-> us. Super+Space cok kolay kazara basiliyordu. */
	.options = "grp:shifts_toggle",
};

static const int repeat_rate = 35;
static const int repeat_delay = 250;

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
/* You can choose between:
LIBINPUT_CONFIG_SCROLL_NO_SCROLL
LIBINPUT_CONFIG_SCROLL_2FG
LIBINPUT_CONFIG_SCROLL_EDGE
LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN
*/
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;

/* You can choose between:
LIBINPUT_CONFIG_CLICK_METHOD_NONE
LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS
LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER
*/
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;

/* You can choose between:
LIBINPUT_CONFIG_SEND_EVENTS_ENABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE
*/
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;

/* You can choose between:
LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT
LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE
*/
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;

/* You can choose between:
LIBINPUT_CONFIG_TAP_MAP_LRM -- 1/2/3 finger tap maps to left/right/middle
LIBINPUT_CONFIG_TAP_MAP_LMR -- 1/2/3 finger tap maps to left/middle/right
*/
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* If you want to use the windows key for MODKEY, use WLR_MODIFIER_LOGO */
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, KEY,            tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,KEY,toggletag,  {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* acik pencere varsa ona git, yoksa calistir: APP("app id parcasi", "komut") */
#define APP(id, cmd) { .v = (const char*[]){ id, "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "alacritty", "--config-file", "/home/savpavi/.local/state/dwl-theme/alacritty.toml", NULL };
static const char *menucmd[] = { "fuzzel", "--config=/home/savpavi/.local/state/dwl-theme/fuzzel.ini", NULL };

static const Key keys[] = {
	/* Hyprland'deki aliskanliklarla ayni tutuldu */
	/* modifier                  key                  function          argument */
	{ MODKEY,                    XKB_KEY_q,           spawn,            {.v = termcmd} },
	{ WLR_MODIFIER_ALT,          XKB_KEY_space,       spawn,            {.v = menucmd} },
	{ MODKEY,                    XKB_KEY_c,           killclient,       {0} },
	{ MODKEY,                    XKB_KEY_e,           spawn,            SHCMD("dolphin") },
	{ MODKEY,                    XKB_KEY_b,           focusorspawn,     APP("=brave-origin", "gtk-launch brave-origin") },
	{ MODKEY,                    XKB_KEY_w,           spawn,            SHCMD("/home/savpavi/.local/bin/start-windows-looking-glass") },
	{ MODKEY,                    XKB_KEY_s,           focusorspawn,     APP("spotify", "spotify-launcher") },
	{ MODKEY,                    XKB_KEY_t,           focusorspawn,     APP("telegram", "Telegram") },
	{ MODKEY,                    XKB_KEY_d,           focusorspawn,     APP("discord", "discord") },
	{ MODKEY,                    XKB_KEY_z,           focusorspawn,     APP("dev.zed", "zeditor") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_z,           focusorspawn,     APP("dev.zed", "zeditor") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_c,           focusorspawn,     APP("claude", "claude-desktop") },
	{ MODKEY,                    XKB_KEY_o,           focusorspawn,     APP("obsidian", "/usr/bin/obsidian") },
	{ 0,                         XKB_KEY_Print,       spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-shot region") },
	{ WLR_MODIFIER_SHIFT,        XKB_KEY_Print,       spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-shot edit") },
	{ MODKEY,                    XKB_KEY_Print,       spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-shot screen") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_d,           spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-grab") },
	{ MODKEY|WLR_MODIFIER_CTRL,  XKB_KEY_d,           spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-grab --clip") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_space,       spawn,            SHCMD("WEBKIT_DISABLE_DMABUF_RENDERER=1 /home/savpavi/Applications/DigUp.AppImage --toggle") },
	{ MODKEY,                    XKB_KEY_x,           spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-clip") },
	{ MODKEY,                    XKB_KEY_k,           spawn,            SHCMD("/home/savpavi/Projects/dwl/bin/dwl-keys") },
	{ MODKEY,                    XKB_KEY_l,           spawn,            SHCMD("quickshell ipc -p /home/savpavi/Projects/dwl/bar call lock lock") },
	{ MODKEY,                    XKB_KEY_Escape,      spawn,            SHCMD("quickshell ipc -p /home/savpavi/Projects/dwl/bar call panel toggle power") },
	{ MODKEY,                    XKB_KEY_n,           spawn,            SHCMD("quickshell ipc -p /home/savpavi/Projects/dwl/bar call panel toggle notif") },

	{ MODKEY,                    XKB_KEY_Right,       focusstack,       {.i = +1} },
	{ MODKEY,                    XKB_KEY_Down,        focusstack,       {.i = +1} },
	{ MODKEY,                    XKB_KEY_Left,        focusstack,       {.i = -1} },
	{ MODKEY,                    XKB_KEY_Up,          focusstack,       {.i = -1} },
	{ MODKEY|WLR_MODIFIER_CTRL,  XKB_KEY_Left,        setmfact,         {.f = -0.05f} },
	{ MODKEY|WLR_MODIFIER_CTRL,  XKB_KEY_Right,       setmfact,         {.f = +0.05f} },
	{ MODKEY|WLR_MODIFIER_CTRL,  XKB_KEY_Up,          incnmaster,       {.i = +1} },
	{ MODKEY|WLR_MODIFIER_CTRL,  XKB_KEY_Down,        incnmaster,       {.i = -1} },
	{ MODKEY,                    XKB_KEY_Return,      zoom,             {0} },
	{ MODKEY,                    XKB_KEY_Tab,         view,             {0} },
	{ MODKEY,                    XKB_KEY_m,           focusorspawn,     APP("mailcraft", "flatpak run io.github.billsecond.mailcraft") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_m,           setlayout,        {.v = &layouts[0]} },
	{ MODKEY,                    XKB_KEY_f,           setlayout,        {.v = &layouts[2]} },
	{ MODKEY,                    XKB_KEY_v,           togglefloating,   {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_f,           togglefullscreen, {0} },
	{ MODKEY,                    XKB_KEY_0,           view,             {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_0,           tag,              {.ui = ~0} },
	{ MODKEY,                    XKB_KEY_comma,       focusmon,         {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,                    XKB_KEY_period,      focusmon,         {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Left,        tagmon,           {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Right,       tagmon,           {.i = WLR_DIRECTION_RIGHT} },

	{ 0, XKB_KEY_XF86AudioRaiseVolume, spawn, SHCMD("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+") },
	{ 0, XKB_KEY_XF86AudioLowerVolume, spawn, SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },
	{ 0, XKB_KEY_XF86AudioMute,        spawn, SHCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
	{ 0, XKB_KEY_XF86AudioPlay,        spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioPause,       spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioNext,        spawn, SHCMD("playerctl next") },
	{ 0, XKB_KEY_XF86AudioPrev,        spawn, SHCMD("playerctl previous") },

	TAGKEYS(                     XKB_KEY_1,           0),
	TAGKEYS(                     XKB_KEY_2,           1),
	TAGKEYS(                     XKB_KEY_3,           2),
	TAGKEYS(                     XKB_KEY_4,           3),
	TAGKEYS(                     XKB_KEY_5,           4),
	TAGKEYS(                     XKB_KEY_6,           5),
	TAGKEYS(                     XKB_KEY_7,           6),
	TAGKEYS(                     XKB_KEY_8,           7),
	TAGKEYS(                     XKB_KEY_9,           8),
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_space, spawn, SHCMD("/home/savpavi/Projects/dwl/bin/dwl-theme pick") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_q,           quit,             {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_BackSpace, quit, {0} },
	/* Ctrl-Alt-Fx is used to switch to another VT, if you don't know what a VT is
	 * do not remove them.
	 */
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_F##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};

static const Axis axes[] = {
	{ MODKEY, AxisUp,   focusstack, {.i = -1} },
	{ MODKEY, AxisDown, focusstack, {.i = +1} },
};

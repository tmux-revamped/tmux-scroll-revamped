#!/bin/sh
# shellcheck disable=SC2034

[ -n "${SCROLL_REVAMPED_STATE_LOADED:-}" ] && return 0
SCROLL_REVAMPED_STATE_LOADED=1

SCROLL_REVAMPED_SETTINGS='mouse	on
wheel	off
passthrough_alternate	on
passthrough_mouse	on
skip_empty	off
alt_keys	
select_pane	off
speed	
granularity	line
auto_exit	off
indicator	off
drag_copy	off
click_copy	off
smooth	off
status_wheel	off'
SCROLL_REVAMPED_NAMES='mouse wheel passthrough_alternate passthrough_mouse skip_empty alt_keys select_pane speed granularity auto_exit indicator drag_copy click_copy smooth status_wheel'
SCROLL_REVAMPED_S_mouse='on'
SCROLL_REVAMPED_S_wheel='off'
SCROLL_REVAMPED_S_passthrough_alternate='on'
SCROLL_REVAMPED_S_passthrough_mouse='on'
SCROLL_REVAMPED_S_skip_empty='off'
SCROLL_REVAMPED_S_alt_keys=''
SCROLL_REVAMPED_S_select_pane='off'
SCROLL_REVAMPED_S_speed=''
SCROLL_REVAMPED_S_granularity='line'
SCROLL_REVAMPED_S_auto_exit='off'
SCROLL_REVAMPED_S_indicator='off'
SCROLL_REVAMPED_S_drag_copy='off'
SCROLL_REVAMPED_S_click_copy='off'
SCROLL_REVAMPED_S_smooth='off'
SCROLL_REVAMPED_S_status_wheel='off'
SCROLL_REVAMPED_MAX_REPEATS=20
SCROLL_REVAMPED_CACHE_KEY=@scroll_revamped_cache_key
SCROLL_REVAMPED_CACHE_VAL=@scroll_revamped_cache_val
SCROLL_REVAMPED_PLAN=""
SCROLL_REVAMPED_TMUX=""
SCROLL_REVAMPED_COUNT=""
SCROLL_REVAMPED_STOCK_LINES=5
SCROLL_REVAMPED_CLICK_SECONDS=0.3
SCROLL_REVAMPED_SMOOTH_SECONDS=0.005
SCROLL_REVAMPED_SMOOTHED=0
SCROLL_REVAMPED_TUNED=0
SCROLL_REVAMPED_FIRST=""
SCROLL_REVAMPED_TOOL=""
REVAMPED_LOG_NS=scroll-revamped
SCROLL_REVAMPED_KINDS='mouse	on off
wheel	on off
passthrough_alternate	on off
passthrough_mouse	on off
skip_empty	on off
select_pane	on off
auto_exit	on off
indicator	on off
drag_copy	on off
click_copy	on off
smooth	on off
status_wheel	on off
alt_keys	arrow page
speed	number 1
granularity	line halfpage page'

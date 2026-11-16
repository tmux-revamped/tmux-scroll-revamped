#!/bin/sh
# shellcheck disable=SC2034

[ -n "${SCROLL_REVAMPED_CORE_LOADED:-}" ] && return 0
SCROLL_REVAMPED_CORE_LOADED=1

readonly SCROLL_REVAMPED_VERSION="3.0.0"

#!/bin/sh

scroll_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${scroll_revamped_dir}/bin/scroll-revamped" apply

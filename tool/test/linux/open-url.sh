#!/usr/bin/env bash
# Stand-in web browser of the E2E desktop: records the URLs the app opens.
printf '%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$*" >>"$HOME/e2e/opened-urls.log"

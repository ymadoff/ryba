#!/usr/bin/env bash

/var/lib/hue/build/env/bin/hue syncdb --noinput
/var/lib/hue/build/env/bin/hue migrate
/var/lib/hue/build/env/bin/supervisor -p {{pid_file}}

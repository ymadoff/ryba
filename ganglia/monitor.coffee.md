---
title: Ganglia Monitor
module: ryba/ganglia/monitor
layout: module
---

# Ganglia Monitor

Ganglia Monitor is the agent to be deployed on each of the hosts.

    module.exports = []

    # module.exports.push command: 'backup', modules: 'ryba/ganglia/monitor_backup'

    # module.exports.push commands: 'check', modules: 'ryba/ganglia/monitor_check'

    module.exports.push commands: 'install', modules: 'ryba/ganglia/monitor_install'

    module.exports.push commands: 'start', modules: 'ryba/ganglia/monitor_start'

    # module.exports.push commands: 'status', modules: 'ryba/ganglia/monitor_status'

    module.exports.push commands: 'stop', modules: 'ryba/ganglia/monitor_stop'





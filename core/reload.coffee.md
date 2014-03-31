---
title: Reload
module: phyla/core/reload
layout: page
---

    module.exports = []
    module.exports.push 'phyla/core/network_restart'
    module.exports.push 'phyla/core/dns'
    module.exports.push 'phyla/core/network'
    module.exports.push 'phyla/core/proxy'
    module.exports.push 'phyla/core/curl'
    module.exports.push 'phyla/core/yum'
    module.exports.push 'phyla/core/ntp'

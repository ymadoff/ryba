---
title: 
layout: module
---

# MapRed

    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push module.exports.configure = (ctx) ->
      # Define Users and Groups
      ctx.config.hdp.mapred_user ?= 'mapred'
      ctx.config.hdp.mapred_group ?= 'hadoop'
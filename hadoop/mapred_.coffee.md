---
title: 
layout: module
---

# MapRed

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push module.exports.configure = (ctx) ->
      # Define Users and Groups
      ctx.config.hdp.mapred_user ?= 'mapred'
      ctx.config.hdp.mapred_group ?= 'hadoop'
      # Options for mapred-site.xml
      ctx.config.hdp.mapred ?= {}
      ctx.config.hdp.mapred['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
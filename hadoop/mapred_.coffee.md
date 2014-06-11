---
title: 
layout: module
---

# MapRed

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push module.exports.configure = (ctx) ->
      # Options for mapred-site.xml
      ctx.config.hdp.mapred ?= {}
      ctx.config.hdp.mapred['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
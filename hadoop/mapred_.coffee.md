---
title: 
layout: module
---

# MapRed

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push module.exports.configure = (ctx) ->
      # Options for mapred-site.xml
      mapred = ctx.config.hdp.mapred ?= {}
      mapred['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
      # The value is set by the client app and the iptables are enforced on the worker nodes
      mapred['yarn.app.mapreduce.am.job.client.port-range'] ?= '59100-59200'
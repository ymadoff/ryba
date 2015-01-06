---
title: 
layout: module
---

# YARN Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./yarn_client').configure

## Configuration

yarn.app.mapreduce.am.command-opts: In YARN, the ApplicationMaster(AM) is
responsible for securing necessary resources. So this property defines how much
memory required to run AM itself. Don't confuse this with NodeManager, where job
will be executed.

yarn.app.mapreduce.am.resource.mb: This property specify criteria to select 
resource for particular job. Any NodeManager which has equal or more memory
available than the one defined by this property will get selected for executing
the job.

    module.exports.push name: 'Hadoop YARN # Configuration', callback: (ctx, next) ->
      {hadoop_conf_dir, yarn_user, yarn_group, yarn_site} = ctx.config.ryba
      properties = {}
      for k, v of yarn_site
        continue if k isnt 'yarn.application.classpath' and k.indexOf('yarn.resourcemanager') is -1
        properties[k] = v
      yarn_site_memory = memory(ctx).yarn_site
      properties['yarn.app.mapreduce.am.resource.mb'] ?= yarn_site_memory['yarn.app.mapreduce.am.resource.mb']
      properties['yarn.app.mapreduce.am.command-opts'] ?= yarn_site_memory['yarn.app.mapreduce.am.command-opts']
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: properties
        merge: true
        uid: yarn_user.name
        gid: yarn_group.name
      , next


## Module Dependencies

    memory = require '../lib/memory'


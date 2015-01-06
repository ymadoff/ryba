---
title: 
layout: module
---

# YARN Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./yarn_client').configure

    module.exports.push name: 'Hadoop YARN # Configuration', callback: (ctx, next) ->
      {hadoop_conf_dir, yarn} = ctx.config.ryba
      config = {}
      for k, v of yarn.site
        continue if k isnt 'yarn.application.classpath' and k.indexOf('yarn.resourcemanager') is -1
        config[k] = v
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: config
        merge: true
        uid: yarn.user.name
        gid: yarn.group.name
      , next


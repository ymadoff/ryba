---
title: 
layout: module
---

# YARN Client

    {merge} = require 'mecano/lib/misc'
    properties = require '../lib/properties'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push require('./yarn').configure

    module.exports.push name: 'HDP YARN # Configuration', callback: (ctx, next) ->
      {hadoop_conf_dir, yarn_user, yarn_group, yarn_site} = ctx.config.ryba
      yarn_site = merge {}, yarn_default, yarn_site
      config = {}
      for k, v of yarn_site
        continue if k isnt 'yarn.application.classpath' and k.indexOf('yarn.resourcemanager') is -1
        config[k] = v
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/files/core_hadoop/yarn-site.xml"
        local_default: true
        properties: config
        merge: true
        uid: yarn_user.name
        gid: yarn_group.name
      , next


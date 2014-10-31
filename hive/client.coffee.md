---
title: 
layout: module
---

# Hive & HCat Client

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx

    module.exports.push commands: 'install', modules: 'ryba/hive/client_install'

    module.exports.push commands: 'check', modules: 'ryba/hive/client_check'


















# Hive Server Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./server').configure

## Start Wait Database

    module.exports.push name: 'Hive & HCat Server # Start Wait DB', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      {hive} = ctx.config.ryba
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive.site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, next

## Start Hive HCatalog

Execute these commands on the Hive HCatalog (Metastore) host machine.

    module.exports.push name: 'Hive & HCat Server # Start HCatalog', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      ctx.service
        srv_name: 'hive-hcatalog-server'
        action: 'start'
        if_exists: '/etc/init.d/hive-hcatalog-server'
      , next

## Start Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'Hive & HCat Server # Start Server2', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, next

## Module Dependencies

    lifecycle = require '../lib/lifecycle'
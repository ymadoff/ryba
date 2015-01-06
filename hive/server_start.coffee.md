
# Hive Server Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./server').configure

## Start Hive HCatalog

Execute these commands on the Hive HCatalog (Metastore) host machine.

    module.exports.push name: 'Hive & HCat Server # Start HCatalog', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      {hive_site} = ctx.config.ryba
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive_site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, (err) ->
        return next err if err
        lifecycle.hive_metastore_start ctx, next

## Start Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'Hive & HCat Server # Start Server2', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, next

## Module Dependencies

    lifecycle = require '../lib/lifecycle'
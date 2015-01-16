
# Hive Server Info

Retrieve various info about the HCatalog Server and the Hive Server2.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push 'ryba/hive/server_wait'
    module.exports.push require('./server').configure

## Info FS Roots

List the current FS root locations for the Hive databases.

    module.exports.push name: 'Hive & HCat Server # Info FS Roots', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.hdfs ctx, "hive --service metatool -listFSRoot 2>/dev/nul"
      , (err, _, stdout) ->
        return next err if err
        count = 0
        for line in string.lines stdout
          continue unless /^hdfs:\/\//.test line
          ctx.report "FS Root #{++count}", line
        next null, true

## Module Dependencies

    mkcmd = require '../lib/mkcmd'
    string = require 'mecano/lib/misc/string'


mecano = require 'mecano'
misc = require 'mecano/lib/misc'

module.exports = []

module.exports.push (ctx) ->
  ctx.config.hbase_master ?= {}
  ctx.config.hbase_master.rest_pidfile ?= '/var/run/hbase/hbase-rest.pid'
  ctx.config.hbase_master.rest_port ?= 8070
  ctx.config.hbase_master.rest_infoport ?= 8071

module.exports.push (ctx, next) ->
  {rest_pidfile, rest_port, rest_infoport} = ctx.config.hbase_master
  @name 'HBase # Rest'
  ctx.log 'Check if HBase Rest is running'
  opts = 
    stdout: ctx.log.out
    stderr: ctx.log.err
  misc.pidfileStatus ctx.ssh, rest_pidfile, opts, (err, status) ->
    return next err if err
    if status is 0
      ctx.log 'HBase Rest is running, continue'
      return next null, ctx.PASS
    ctx.execute
      cmd: "hbase rest start --infoport #{rest_infoport} -p #{rest_port} </dev/null >/dev/null 2>&1 & echo $! > #{rest_pidfile}"
    , (err, executed) ->
      next err, ctx.OK

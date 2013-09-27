
module.exports = (ctx, next) ->
  @name 'HBase: clean logs'
  ctx.ssh.exec 'rm -rf /var/log/hbase/*', (err, stream) ->
    return next err if err
    stream.on 'exit', (code, signal) ->
      next null, if code is 0 then ctx.OK else ctx.PASS


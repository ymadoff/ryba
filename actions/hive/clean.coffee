
module.exports = []

module.exports.push (ctx, next) ->
    @name 'Hive: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hive/*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next null, if code is 0 then ctx.OK else ctx.PASS



mecano = require 'mecano'

module.exports = [
  (ctx, next) ->
    @name 'Oozie: clean logs'
    ctx.execute
      cmd: 'rm -rf /var/log/oozie/*'
    (err, executed) ->
      next err, ctx.OK
]

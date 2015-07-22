
# MongoDB Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the MongoDB service.

    module.exports.push name: 'MongoDB Server # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'mongod'
        action: 'stop'
      .then next

## Stop Clean Logs

    module.exports.push name: 'MongoDB Server # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      {mongodb} = ctx.config.ryba
      ctx.execute
        cmd: "rm #{mongodb.log_dir}/*"
        code_skipped: 1
      .then next


# Solr Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push name: 'Solr # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service solr status'
        code_skipped: 3
      , next

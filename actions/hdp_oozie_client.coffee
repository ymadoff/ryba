
module.exports = []

module.exports.push 'histi/actions/hdp_oozie_'

module.exports.push (ctx) ->
  require('./hdp_oozie_').configure ctx

module.exports.push (ctx, next) ->
  {oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.hdp
  @name "HDP Oozie Client # Check Client"
  ctx.execute
    cmd: """
    if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
    oozie admin -oozie #{oozie_site['oozie.base.url']} -status
    """
  , (err, executed, stdout) ->
    return next err if err
    return next new Error "Oozie not started" if stdout.trim() isnt 'System mode: NORMAL'
    return next null, ctx.PASS

module.exports.push (ctx, next) ->
  {oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.hdp
  @name "HDP Oozie Client # Check REST"
  ctx.execute
    cmd: """
    if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
    curl -s --negotiate -u : #{oozie_site['oozie.base.url']}/v1/admin/status
    """
  , (err, executed, stdout) ->
    return next err if err
    return next new Error "Oozie not started" if stdout.trim() isnt '{"systemMode":"NORMAL"}'
    return next null, ctx.PASS
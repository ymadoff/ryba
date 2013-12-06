
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  oozie_server = (ctx.config.servers.filter (s) -> s.hdp?.oozie_server)[0].host
  {realm} = ctx.config.krb5_client
  ctx.config.hdp.oozie_user ?= 'oozie'
  ctx.config.hdp.oozie_test_principal ?= "oozietest@#{realm}"
  ctx.config.hdp.oozie_test_password ?= "ooziepass"
  ctx.config.hdp.oozie_conf_dir ?= '/etc/oozie/conf'
  ctx.config.hdp.oozie_data ?= '/var/db/oozie'
  ctx.config.hdp.oozie_log_dir ?= '/var/log/oozie'
  ctx.config.hdp.oozie_pid_dir ?= '/var/run/oozie'
  ctx.config.hdp.oozie_tmp_dir ?= '/var/tmp/oozie'
  ctx.config.hdp.oozie_site ?= {}
  ctx.config.hdp.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # Install'
  @timeout -1
  ctx.service [
    name: 'oozie-client'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # Environment"
  {oozie_user, hadoop_group, oozie_conf_dir} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/hdp/oozie/oozie-env.sh"
    destination: "#{oozie_conf_dir}/oozie-env.sh"
    context: ctx
    local_source: true
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

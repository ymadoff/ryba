
module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push module.exports.configure = (ctx) ->
  return if ctx.oozie__configured
  ctx.oozie__configured = true
  require('./core').configure ctx
  oozie_server = ctx.host_with_module 'phyla/hdp/oozie_server'
  {realm} = ctx.config.hdp
  ctx.config.hdp.oozie_port ?= 11000
  ctx.config.hdp.oozie_user ?= 'oozie'
  ctx.config.hdp.oozie_test_principal ?= "test@#{realm}"
  ctx.config.hdp.oozie_test_password ?= "test123"
  ctx.config.hdp.oozie_conf_dir ?= '/etc/oozie/conf'
  ctx.config.hdp.oozie_data ?= '/var/db/oozie'
  ctx.config.hdp.oozie_log_dir ?= '/var/log/oozie'
  ctx.config.hdp.oozie_pid_dir ?= '/var/run/oozie'
  ctx.config.hdp.oozie_tmp_dir ?= '/var/tmp/oozie'
  ctx.config.hdp.oozie_site ?= {}
  ctx.config.hdp.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"

module.exports.push name: 'HDP Oozie # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'oozie-client'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie # Users & Groups', callback: (ctx, next) ->
  {oozie_user, hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd oozie -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop Oozie service\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie # Environment', callback: (ctx, next) ->
  {oozie_user, hadoop_group, oozie_conf_dir} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/files/oozie/oozie-env.sh"
    destination: "#{oozie_conf_dir}/oozie-env.sh"
    context: ctx
    local_source: true
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie # Profile', callback: (ctx, next) ->
  {oozie_site} = ctx.config.hdp
  ctx.write
    destination: '/etc/profile.d/oozie.sh'
    content: """
    #!/bin/bash
    export OOZIE_URL=#{oozie_site['oozie.base.url']}
    """
    mode: 0o0755
  , (err, written) ->
    next null, if written then ctx.OK else ctx.PASS

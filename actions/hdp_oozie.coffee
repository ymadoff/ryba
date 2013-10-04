
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  ctx.config.hdp_oozie ?= {}
  ctx.config.hdp_oozie.conf_dir ?= '/var/db/oozie'
  ctx.config.hdp_oozie.data ?= '/var/log/oozie'
  ctx.config.hdp_oozie.log_dir ?= '/var/log/oozie'
  ctx.config.hdp_oozie.pid_dir ?= '/var/run/oozie'
  ctx.config.hdp_oozie.tmp_dir ?= '/var/tmp/oozie'
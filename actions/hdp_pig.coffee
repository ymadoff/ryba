
module.exports = []

module.exports.push (ctx) ->
  ctx.config.hdp.pig_user ?= 'pig'
  ctx.config.hdp.pig_conf_dir ?= '/etc/pig/conf'

###
http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html
###
module.exports.push (ctx, next) ->
  @name 'HDP Pig # Install'
  @timeout -1
  ctx.service
    name: 'pig'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Pig # Users'
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd pig -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop Pig service\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Pig # Configure'
  # Note, HDP default file comes without any config. We
  # could do the same, start with empty config object
  # that user could overwrite
  next null, ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Pig # Env'
  ctx.ini
    content:
      'JAVA_HOME': '/usr/java/default'
      'HADOOP_HOME': '${HADOOP_HOME:-/etc/hadoop/conf}'
    backup: true
    destination: '/etc/pig/conf/pig-env.sh'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS


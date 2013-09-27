
module.exports = []

###
http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html
###
module.exports.push (ctx, next) ->
  @name 'HDP PIG # Install'
  ctx.service
    name: 'pig'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP PIG # Configure'
  # Note, HDP default file comes without any config. We
  # could do the same, start with empty config object
  # that user could overwrite
  next null, ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP PIG # Env'
  ctx.ini
    content:
      'JAVA_HOME': '/usr/java/default'
      'HADOOP_HOME': '${HADOOP_HOME:-/etc/hadoop/conf}'
    backup: true
    destination: '/etc/pig/conf/pig-env.sh'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS


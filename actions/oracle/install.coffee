

###
Oracle SQL Connector for HDFS
http://docs.oracle.com/cd/E37231_01/doc.20/e36961/start.htm#CHDBHGGI
###

module.exports = []

module.exports.push (ctx) ->
  ctx.oracle ?= {}
  ctx.oracle.path ?= '/usr/lib/orahdfs-2.0.1'

module.exports.push (ctx, next) ->
  ctx.upload
    source: "#{__dirname}/../../data/oraosch-2.0.1.zip"
    destination: "/tmp"
    not_if_exists: ctx.oracle.path
  , (err, uploaded) ->
    ctx.execute
      cmd: 'tar xzf /tmp/oraosch-2.0.1.zip'
    , (err, executed) ->
      ctx.execute
        cmd: 'tar xzf /tmp/oraosch-2.0.1/orahdfs-2.0.1.zip'
      , (err, executed) ->
        ctx.move
          source: '/tmp/oraosch-2.0.1/orahdfs-2.0.1'
          destination: ctx.oracle.path
        , (err, moved) ->
          # Oracle
          export OSCH_HOME=/usr/lib/orahdfs-2.0.1
          export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:$OSCH_HOME/jlib/*"
          export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/lib/hive/lib/*"
          export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/etc/hive/conf"
          ctx.write
            destination: '/home/big/.bash_profile'
            match: /^OSCH_HOME=.*/mg
            replace: "OSCH_HOME=#{ctx.oracle.path}"

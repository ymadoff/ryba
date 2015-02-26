
# Tez Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push require('./index').configure

## Packages

    module.exports.push name: 'Tez # Packages', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'tez'
      , next

## HDFS Layout

    module.exports.push name: 'Tez # HDFS Layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      # Group name on "/apps/tez" is suggested as "users", switch to hadoop
      version_local = 'ls /usr/lib/tez | grep tez-common | sed \'s/^tez-common-\\(.*\\)\\.jar$/\\1/g\''
      version_remote = 'hdfs dfs -ls /apps/tez | grep tez-common | sed \'s/.*tez-common-\\(.*\\)\\.jar$/\\1/g\''
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        hdfs dfs -rm -r -f /apps/tez || true
        hdfs dfs -mkdir -p /apps/tez
        hdfs dfs -copyFromLocal /usr/lib/tez/* /apps/tez
        hdfs dfs -chown -R  #{hdfs.user.name}:#{hadoop_group.name} /apps/tez
        hdfs dfs -chmod 755 /apps
        hdfs dfs -chmod 755 /apps/tez
        hdfs dfs -chmod 755 /apps/tez/lib/
        hdfs dfs -chmod 644 /apps/tez/*.jar
        hdfs dfs -chmod 644 /apps/tez/lib/*.jar
        """
        trap_on_error: true
        not_if_exec: mkcmd.hdfs ctx, "[[ `#{version_local}` == `#{version_remote}` ]]"
      , next

## Configuration

    module.exports.push name: 'Tez # Configuration', timeout: -1, handler: (ctx, next) ->
      {tez} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{tez.env['TEZ_CONF_DIR']}/tez-site.xml"
        default: "#{__dirname}/../resources/tez/tez-site.xml"
        local_default: true
        properties: tez.tez_site
        merge: true
      , next

## Environment

Environment passed to Hadoop.   

    module.exports.push name: 'Tez # Environment', handler: (ctx, next) ->
      {hadoop_conf_dir, tez} = ctx.config.ryba
      env = for k, v of tez.env
        "export #{k}=#{v}"
      classpath = "#{tez.env['TEZ_CONF_DIR']}:#{tez.env['TEZ_JARS']}"
      ctx.write [
        destination: '/etc/profile.d/tez.sh'
        content: env.join '\n'
        mode: 0o0644
        eof: true
      ,
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_CLASSPATH="(.*):\$\{HADOOP_CLASSPATH\}" # RYBA TEZ CLASSPATH, DONT OVEWRITE/mg
        replace: "export HADOOP_CLASSPATH=\"#{classpath}:${HADOOP_CLASSPATH}\" # RYBA TEZ CLASSPATH, DONT OVEWRITE"
        before: /^export HADOOP_CLASSPATH=.*$/mg
        backup: true
      ], next

## Dependencies

    mkcmd = require '../lib/mkcmd'







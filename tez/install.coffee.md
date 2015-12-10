
# Tez Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push require '../lib/hdfs_upload'
    # module.exports.push require('./index').configure

## Packages

    module.exports.push header: 'Tez # Packages', timeout: -1, handler: ->
      @service
        name: 'tez'

## HDFS Tarballs

Upload the Tez tarball inside the "/hdp/apps/$version/tez"
HDFS directory. Note, the parent directories are created by the 
"ryba/hadoop/hdfs_dn/layout" module.

    module.exports.push header: 'Tez # HDFS Layout', timeout: -1, handler: ->
      @hdfs_upload
        source: '/usr/hdp/current/tez-client/lib/tez.tar.gz'
        target: '/hdp/apps/$version/tez/tez.tar.gz'
        lock: '/tmp/ryba-tez.lock'

## Configuration

    module.exports.push header: 'Tez # Configuration', timeout: -1, handler: ->
      {tez} = @config.ryba
      @hconfigure
        destination: "#{tez.env['TEZ_CONF_DIR']}/tez-site.xml"
        default: "#{__dirname}/resources/tez-site.xml"
        local_default: true
        properties: tez.site
        merge: true

## Environment

Environment passed to Hadoop.   

    module.exports.push header: 'Tez # Environment', handler: ->
      {hadoop_conf_dir, tez} = @config.ryba
      env = for k, v of tez.env
        "export #{k}=#{v}"
      classpath = "#{tez.env['TEZ_CONF_DIR']}:#{tez.env['TEZ_JARS']}"
      @write
        destination: '/etc/profile.d/tez.sh'
        content: env.join '\n'
        mode: 0o0644
        eof: true
      # .write
      #   destination: "#{hadoop_conf_dir}/hadoop-env.sh"
      #   match: /^export HADOOP_CLASSPATH="(.*):\$\{HADOOP_CLASSPATH\}" # RYBA TEZ CLASSPATH, DONT OVEWRITE/mg
      #   replace: "export HADOOP_CLASSPATH=\"#{classpath}:${HADOOP_CLASSPATH}\" # RYBA TEZ CLASSPATH, DONT OVEWRITE"
      #   before: /^export HADOOP_CLASSPATH=.*$/mg
      #   backup: true

## Dependencies

    mkcmd = require '../lib/mkcmd'

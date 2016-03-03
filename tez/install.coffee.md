
# Tez Install

    module.exports = header: 'Tez Install', timeout: -1, handler: ->
      {tez, hadoop_conf_dir} = @config.ryba
      
## Packages

      @service
        header: 'Tez Packages'
        name: 'tez'

## HDFS Tarballs

Upload the Tez tarball inside the "/hdp/apps/$version/tez"
HDFS directory. Note, the parent directories are created by the 
"ryba/hadoop/hdfs_dn/layout" module.

      @hdfs_upload
        header: 'HDFS Layout'
        source: '/usr/hdp/current/tez-client/lib/tez.tar.gz'
        target: '/hdp/apps/$version/tez/tez.tar.gz'
        lock: '/tmp/ryba-tez.lock'

## Configuration

      @hconfigure
        header: 'Tez Site'
        destination: "#{tez.env['TEZ_CONF_DIR']}/tez-site.xml"
        default: "#{__dirname}/resources/tez-site.xml"
        local_default: true
        properties: tez.site
        merge: true

## Environment

Environment passed to Hadoop.   

      env = for k, v of tez.env
        "export #{k}=#{v}"
      classpath = "#{tez.env['TEZ_CONF_DIR']}:#{tez.env['TEZ_JARS']}"
      @write
        header: 'Environment'
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


# Tez Install

    module.exports = header: 'Tez Install', timeout: -1, handler: ->
      {tez, hadoop_conf_dir} = @config.ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

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
        target: "#{tez.env['TEZ_CONF_DIR']}/tez-site.xml"
        source: "#{__dirname}/resources/tez-site.xml"
        local_source: true
        properties: tez.site
        merge: true

## Environment

Environment passed to Hadoop.   

      env = for k, v of tez.env
        "export #{k}=#{v}"
      classpath = "#{tez.env['TEZ_CONF_DIR']}:#{tez.env['TEZ_JARS']}"
      @file
        header: 'Environment'
        target: '/etc/profile.d/tez.sh'
        content: env.join '\n'
        mode: 0o0644
        eof: true
      # .write
      #   target: "#{hadoop_conf_dir}/hadoop-env.sh"
      #   match: /^export HADOOP_CLASSPATH="(.*):\$\{HADOOP_CLASSPATH\}" # RYBA TEZ CLASSPATH, DONT OVEWRITE/mg
      #   replace: "export HADOOP_CLASSPATH=\"#{classpath}:${HADOOP_CLASSPATH}\" # RYBA TEZ CLASSPATH, DONT OVEWRITE"
      #   place_before: /^export HADOOP_CLASSPATH=.*$/mg
      #   backup: true

## Tez UI

Tez UI will be untared in the tez.ui.html_path directory. A WebServer must be configured
to serve this directory.

      @call header: 'UI', if: tez.ui.enabled, handler: ->
        @system.mkdir
          header: 'Layout'
          target: tez.ui.html_path
        @execute
          header: 'Web Files'
          cmd: """
          target_file=`ls /usr/hdp/current/tez-client/ui/tez-ui*.war | sed 's/^.*tez/tez/g'`
          cd #{tez.ui.html_path}
          ls ${target_file} >/dev/null 2>&1
          if [ $? -ne 0 ]; then
            rm -rf *
            cp /usr/hdp/current/tez-client/ui/tez-ui*.war .
            jar xf tez-ui*.war
          else
            exit 3
          fi
          """
          code_skipped: 3
        @file
          header: 'Env'
          target: "#{tez.ui.html_path}/config/configs.env"
          content: "ENV = #{JSON.stringify tez.ui.env, null, '  '};"
          backup: true
          eof: true
        @file
          header: 'Fix HTTPS'
          target: "#{tez.ui.html_path}/assets/tez-ui.js"
          write: [
            match: "      url = this.correctProtocol(url);"
            replace: "      //url = this.correctProtocol(url);"
          ]
          backup: true

## Dependencies

    mkcmd = require '../lib/mkcmd'

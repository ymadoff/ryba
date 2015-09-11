
# YARN Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push require '../../lib/hconfigure'
    # module.exports.push require('./index').configure

    module.exports.push
      name: 'YARN Client # Users & Groups'
      if: -> @config.ryba.resourcemanager or @config.ryba.nodemanager
      handler: ->
        {yarn, hadoop_group} = @config.ryba
        @execute
          cmd: "useradd #{yarn.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
          code: 0
          code_skipped: 9

    module.exports.push name: 'YARN Client # Install Common', timeout: -1, handler: ->
      @service
        name: 'hadoop'
      @service
        name: 'hadoop-yarn'
      @service
        name: 'hadoop-client'

    module.exports.push name: 'YARN Client # Directories', timeout: -1, handler: ->
      {yarn, hadoop_group} = @config.ryba
      pid_dir = yarn.pid_dir.replace '$USER', yarn.user.name
      @mkdir
        destination: "#{yarn.log_dir}/#{yarn.user.name}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        parent: true
      @mkdir
        destination: "#{pid_dir}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        parent: true

    module.exports.push name: 'YARN Client # Yarn OPTS', handler: ->
      {java_home} = @config.java
      {yarn, hadoop_group, hadoop_conf_dir} = @config.ryba
      @render
        source: "#{__dirname}/../../resources/core_hadoop/yarn-env.sh"
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        local_source: true
        write: [
          match: /^export JAVA_HOME=.*$/m
          replace: "export JAVA_HOME=\"#{java_home}\" # RYBA CONF \"java.java_home\", DONT OVEWRITE"
        ,
          match: /^export YARN_PID_DIR=.*$/m
          replace: "export YARN_PID_DIR=\"#{yarn.pid_dir}\" # RYBA CONF \"ryba.yarn.pid_dir\", DONT OVEWRITE"
        ,
          match: /^YARN_OPTS="(.*) \$\{YARN_OPTS\}" # RYBA CONF ".*?", DONT OVERWRITE/m
          replace: "YARN_OPTS=\"#{yarn.opts} ${YARN_OPTS}\" # RYBA CONF \"ryba.yarn.opts\", DONT OVERWRITE"
          before: /^YARN_OPTS=".*"$/m
        ,
          match: /^export YARN_IDENT_STRING=.* # RYBA.*$/m
          replace: "export YARN_IDENT_STRING=${YARN_IDENT_STRING:-yarn} # RYBA FIX rc.d"
          append: /^export HADOOP_YARN_USER=.*$/m
        ]
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

## Configuration

    module.exports.push name: 'YARN Client # Configuration', handler: ->
      {hadoop_conf_dir, yarn} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        backup: true
        uid: yarn.user.name
        gid: yarn.group.name

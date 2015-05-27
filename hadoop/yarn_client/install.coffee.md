
# YARN Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require('./index').configure

## Package

Install the "hadoop-yarn" package.

    module.exports.push name: 'YARN # Package', handler: (ctx, next) ->
      ctx.service
        name: 'hadoop-yarn'
      , next

    module.exports.push name: 'YARN # Users & Groups', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.resourcemanager or ctx.config.ryba.nodemanager
      {yarn, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{yarn.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
        code: 0
        code_skipped: 9
      .then next

    module.exports.push name: 'YARN # Install Common', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'hadoop'
      .service
        name: 'hadoop-yarn'
      .service
        name: 'hadoop-client'
      .then next

    module.exports.push name: 'YARN # Directories', timeout: -1, handler: (ctx, next) ->
      {yarn, hadoop_group} = ctx.config.ryba
      pid_dir = yarn.pid_dir.replace '$USER', yarn.user.name
      ctx.mkdir
        destination: "#{yarn.log_dir}/#{yarn.user.name}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        parent: true
      .mkdir
        destination: "#{pid_dir}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        parent: true
      .then next

    module.exports.push name: 'YARN # Yarn OPTS', handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {yarn, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      ctx.render
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
      .then next

## Configuration

    module.exports.push name: 'YARN # Configuration', handler: (ctx, next) ->
      {hadoop_conf_dir, yarn} = ctx.config.ryba
      # properties = {}
      # for k, v of yarn.site
      #   continue if k isnt 'yarn.application.classpath' and k.indexOf('yarn.resourcemanager') is -1
      #   properties[k] = v
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        uid: yarn.user.name
        gid: yarn.group.name
      .then next



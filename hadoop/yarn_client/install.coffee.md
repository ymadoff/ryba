
# YARN Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/lib/hconfigure'
    # module.exports.push require('./index').configure

    module.exports.push
      header: 'YARN Client # Users & Groups'
      if: -> @config.ryba.resourcemanager or @config.ryba.nodemanager
      handler: ->
        {yarn, hadoop_group} = @config.ryba
        @execute
          cmd: "useradd #{yarn.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
          code: 0
          code_skipped: 9

    module.exports.push header: 'YARN Client # Install Common', timeout: -1, handler: ->
      @service
        name: 'hadoop'
      @service
        name: 'hadoop-yarn'
      @service
        name: 'hadoop-client'

    module.exports.push header: 'YARN Client # Directories', timeout: -1, handler: ->
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

## Yarn OPTS

Inject YARN environmental properties used by the client, nodemanager and
resourcemanager.

Properties accepted by the template are: `ryba.yarn.rm_opts`   

    module.exports.push header: 'YARN Client # Yarn OPTS', handler: ->
      {java_home} = @config.java
      {yarn, hadoop_group, hadoop_conf_dir} = @config.ryba
      @render
        source: "#{__dirname}/../resources/yarn-env.sh"
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        local_source: true
        context: @config
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

## Configuration

    module.exports.push header: 'YARN Client # Configuration', handler: ->
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

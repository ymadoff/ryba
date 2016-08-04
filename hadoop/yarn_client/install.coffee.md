
# YARN Client Install

    module.exports = header: 'YARN Client Install', handler: ->
      {yarn, hadoop_group, hadoop_conf_dir} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'

      # @call
      #   header: 'Users & Groups'
      #   if: -> @config.ryba.resourcemanager or @config.ryba.nodemanager
      #   handler: ->
      #     {yarn, hadoop_group} = @config.ryba
      #     @execute
      #       cmd: "useradd #{yarn.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
      #       code: 0
      #       code_skipped: 9

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'hadoop'
        @service
          name: 'hadoop-yarn'
        @service
          name: 'hadoop-client'

      @call header: 'Layout', timeout: -1, handler: ->
        pid_dir = yarn.pid_dir.replace '$USER', yarn.user.name
        @mkdir
          target: "#{yarn.log_dir}/#{yarn.user.name}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @mkdir
          target: "#{pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true

## Yarn OPTS

Inject YARN environmental properties used by the client, nodemanager and
resourcemanager.

Properties accepted by the template are: `ryba.yarn.rm_opts`   

      @render
        header: 'Yarn OPTS'
        target: "#{hadoop_conf_dir}/yarn-env.sh"
        source: "#{__dirname}/../resources/yarn-env.sh.j2"
        local_source: true
        context: @config
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

## Configuration

      @hconfigure
        header: 'Configuration'
        target: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        backup: true
        uid: yarn.user.name
        gid: yarn.group.name

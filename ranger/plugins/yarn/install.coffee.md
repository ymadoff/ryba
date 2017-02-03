
    module.exports = header: 'Ranger YARN Plugin install', handler: ->
      {ranger, yarn, realm, hadoop_group, core_site, ssl_server} = @config.ryba
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version = null
      conf_dir = null
      @call -> conf_dir = if @config.ryba.yarn_plugin_is_master then yarn.rm.conf_dir else yarn.nm.conf_dir

# HDFS Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

# Packages

      @call header: 'Packages', handler: ->
        @execute
          header: 'Setup Execution'
          shy: true
          cmd: """
            hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-yarn-plugin"

# Layout

      @mkdir
        target: ranger.yarn_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.yarn_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @mkdir
        target: ranger.yarn_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.yarn_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

# YARN Service Repository creation
Matchs step 1 in [hdfs plugin configuration][yarn-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hadoop/yarn_rm')[0].config.host is @config.host 
        header: 'Ranger YARN Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\" -k -X GET  \
              -u admin:#{password} \"#{ranger.yarn_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.yarn_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.yarn_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.yarn_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.yarn_plugin.principal
            header: 'Ranger YARN Principal'
            principal: ranger.yarn_plugin.principal
            randkey: true
            password: ranger.yarn_plugin.password
          @execute
            header: 'Ranger Audit HDFS Layout'
            cmd: mkcmd.hdfs @, """
              hdfs dfs -mkdir -p #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/yarn
              hdfs dfs -chown -R #{yarn.user.name}:#{yarn.user.name} #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/yarn
              hdfs dfs -chmod 750 #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/yarn
            """

# Plugin Scripts 

      @call 
        header: 'Plugin Activation'
        handler: ->
          @render
            header: 'Scripts rendering'
            if: -> version?
            source: "#{__dirname}/../../resources/plugin-install.properties.j2"
            target: "/usr/hdp/#{version}/ranger-yarn-plugin/install.properties"
            local: true
            eof: true
            backup: true
            write: for k, v of ranger.yarn_plugin.install
              match: RegExp "^#{quote k}=.*$", 'mg'
              replace: "#{k}=#{v}"
              append: true
          @file
            header: 'Script Fix'
            target: "/usr/hdp/#{version}/ranger-yarn-plugin/enable-yarn-plugin.sh"
            write:[
                match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
                replace: "HCOMPONENT_CONF_DIR=#{conf_dir}"
              ,
                match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
                replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hadoop-yarn-resourcemanager/lib"
            ]
            backup: true
            mode: 0o750
          @execute
            header: 'Script Execution'
            cmd: """
              export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
              cd /usr/hdp/#{version}/ranger-yarn-plugin/
              ./enable-yarn-plugin.sh
            """
          @execute
            header: "Fix repository "
            cmd: "chown -R #{yarn.user.name}:#{hadoop_group.name} /etc/ranger/#{ranger.yarn_plugin.install['REPOSITORY_NAME']}"
          @hconfigure
            header: 'Fix ranger-yarn-security conf'
            target: "#{conf_dir}/ranger-yarn-security.xml"
            merge: true
            properties:
              'ranger.plugin.yarn.policy.rest.ssl.config.file': "#{conf_dir}/ranger-policymgr-ssl.xml"
          @file
            header: 'Fix Ranger YARN Plugin Env'
            target: "#{conf_dir}/yarn-env.sh"
            write: [
              match: RegExp "^export YARN_OPTS=.*", 'mg'
              replace: "export YARN_OPTS=\"-Dhdp.version=$HDP_VERSION $YARN_OPTS -Djavax.net.ssl.trustStore=#{ssl_server['ssl.server.truststore.location']} -Djavax.net.ssl.trustStorePassword=#{ssl_server['ssl.server.truststore.password']} \" # RYBA, DONT OVERWRITE"
              append: true
            ]

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'

[yarn-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_yarn_plugin)

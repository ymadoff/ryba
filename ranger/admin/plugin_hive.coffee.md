
    module.exports = header: 'Ranger Kafka Plugin install', handler: ->
      {ranger, hive, realm, hadoop_group, core_site} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version=null
      #https://mail-archives.apache.org/mod_mbox/incubator-ranger-user/201605.mbox/%3C363AE5BD-D796-425B-89C9-D481F6E74BAF@apache.org%3E

# Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @register 'hconfigure', 'ryba/lib/hconfigure'

# Packages

      @call header: 'Packages', handler: ->
        @execute
          header: 'Setup Execution'
          shy:true
          cmd: """
            hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-hive-plugin"

# Layout

      @mkdir
        destination: '/var/log/hadoop/hive/audit/hdfs/'
        uid: hive.user.name
        gid: hive.name
        mode: 0o0755
        if: ranger.hive_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @mkdir
        destination: '/var/log/hadoop/hive/audit/solr/'
        uid: hive.user.name
        gid: hive.name
        mode: 0o0755
        if: ranger.hive_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

# HIVE Service Repository creation
Matchs step 1 in [hive plugin configuration][hive-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hive/server2')[0].config.host is @config.host 
        header: 'Ranger HIVE Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H  \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.hive_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.hive_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.hive_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.hive_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.hive_plugin.principal
            header: 'Ranger HIVE Principal'
            principal: ranger.hive_plugin.principal
            randkey: true
            password: ranger.hive_plugin.password
          @execute
            header: 'Ranger Audit HIVE Layout'
            cmd: mkcmd.hdfs @, """
              hdfs dfs -mkdir -p #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hive
              hdfs dfs -chown -R #{hive.user.name}:#{hive.user.name} #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hive
              hdfs dfs -chmod 750 #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hive
            """

# Plugin Scripts 

      @call ->
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../resources/plugin-install.properties.j2"
          destination: "/usr/hdp/#{version}/ranger-hive-plugin/install.properties"
          local_source: true
          eof: true
          backup: true
          write: for k, v of ranger.hive_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @write
          header: 'Script Fix'
          destination: "/usr/hdp/#{version}/ranger-hive-plugin/enable-hive-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{hive.server2.conf_dir}"
            ,   
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/hive-server2"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hive-server2/lib"
            # , 
            #   match: RegExp "^HCOMPONENT_NAME=.*$", 'mg'
            #   replace: "HCOMPONENT_NAME=kafka-broker"

          ]
          backup: true
        # @write
        #   header: 'Fix Hive Server2 classpath'
        #   destination: "#{kafka.broker.conf_dir}/kafka-env.sh"
        #   write: [
        #     match: RegExp "^export CLASSPATH=\"$CLASSPATH.*", 'm'
        #     replace: "export CLASSPATH=\"$CLASSPATH:${script_dir}:/usr/hdp/#{version}/ranger-hive-plugin/lib/ranger-hive-plugin-impl:#{kafka.broker.conf_dir}:/usr/hdp/current/hadoop-hdfs-client/*:/usr/hdp/current/hadoop-hdfs-client/lib/*:/etc/hadoop/conf\" # RYBA, DONT OVERWRITE"
        #     append: true
        #   ]
        #   backup: true
        #   eof: true
        #   mode:0o0750
        #   uid: kafka.user.name
        #   gid: kafka.group.name
        @execute
          header: 'Script Execution'
          cmd: """
            if /usr/hdp/#{version}/ranger-hive-plugin/enable-hive-plugin.sh ;
            then exit 0 ; 
            else exit 1 ; 
            fi;
          """
        @hconfigure
          header: 'Fix hiveserver2 hive-site'
          destination: "#{hive.server2.conf_dir}/hive-site.xml"
          merge: true
          properties:
            'hive.security.authorization.manager':'org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory'
            'hive.security.authenticator.manager':'org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator'
        @hconfigure
          header: 'Fix ranger-hive-security conf'
          destination: "#{hive.server2.conf_dir}/ranger-hive-security.xml"
          merge: true
          properties:
            'ranger.plugin.hive.policy.rest.ssl.config.file': "#{hive.server2.conf_dir}/ranger-policymgr-ssl.xml"
        @remove
          header: 'Remove useless file'
          destination: "#{hive.server2.conf_dir}/hiveserver2-site.xml"

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../lib/mkcmd'


[hive-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hive_plugin)

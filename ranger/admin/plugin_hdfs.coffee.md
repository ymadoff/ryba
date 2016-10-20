# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin install', handler: ->
      {ranger, hdfs, hadoop_group, realm, ssl_server} = @config.ryba
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version=null

## HDFS Dependencies

      @call 'ryba/hadoop/hdfs_client/install'
      @call 'ryba/ranger/admin/wait'
      @register 'hconfigure', 'ryba/lib/hconfigure'

## Packages

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
          name: "ranger-hdfs-plugin"

## Layout

      @mkdir
        target: ranger.hdfs_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.hdfs_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @mkdir
        target: ranger.hdfs_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.hdfs_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

## HDFS Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hdfs-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hadoop/hdfs_nn')[0].config.host is @config.host 
        header: 'Ranger HDFS Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H  \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.hdfs_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.hdfs_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.hdfs_plugin.principal
            header: 'Ranger HDFS Principal'
            principal: ranger.hdfs_plugin.principal
            randkey: true
            password: ranger.hdfs_plugin.password

## Plugin Scripts 

      @call ->
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/install.properties"
          local_source: true
          eof: true
          backup: true
          write: for k, v of ranger.hdfs_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{hdfs.nn.conf_dir}"
            ,   
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/hadoop-hdfs-namenode"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hadoop-hdfs-namenode/lib"
          ]
          backup: true
        @execute
          header: 'Script Execution'
          cmd: """
            export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
             if /usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh ;
            then exit 0 ; 
            else exit 1 ; 
            fi;
          """
        @hconfigure
          header: 'Fix ranger-hdfs-security conf'
          target: "#{hdfs.nn.conf_dir}/ranger-hdfs-security.xml"
          merge: true
          properties:
            'ranger.plugin.hdfs.policy.rest.ssl.config.file': "#{hdfs.nn.conf_dir}/ranger-policymgr-ssl.xml"
        @file
          header: 'Fix Ranger HDFS Plugin Env'
          destination: "#{hdfs.nn.conf_dir}/hadoop-env.sh"
          write: [
            match: RegExp "^export HADOOP_OPTS=.*", 'mg'
            replace: "export HADOOP_OPTS=\"-Dhdp.version=$HDP_VERSION $HADOOP_OPTS -Djavax.net.ssl.trustStore=#{ssl_server['ssl.server.truststore.location']} -Djavax.net.ssl.trustStorePassword=#{ssl_server['ssl.server.truststore.password']} \" # RYBA, DONT OVERWRITE"
            append: true
          ]
          
          backup: true
          eof: true
          mode:0o0750
          uid: hdfs.user.name
          gid: hdfs.group.name

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'


[hdfs-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin)

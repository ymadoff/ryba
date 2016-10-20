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
From HDP 2.5 (Ranger 0.6) hdfs plugin need a Client JAAS configuration file to
talk with kerberized component.
The JAAS configuration can be donne with a jaas file and the Namenonde Env property
auth.to.login.conf or can be set by properties in ranger-hdfs-audit.xml file.
Not documented be taken from [github-source][hdfs-plugin-source]

      @call ->
        # wrap into call for version to be not null
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of ranger.hdfs_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @call
          header: 'Enable HDFS Plugin'
          handler: (options, callback) ->
            files = ['ranger-hdfs-audit.xml','ranger-hdfs-security.xml','ranger-policymgr-ssl.xml', 'hdfs-site.xml']
            sources_props = {}
            current_props = {}
            files_exists = {}
            @execute
              cmd: """
                echo '' | keytool -list \
                -storetype jceks \
                -keystore /etc/ranger/#{ranger.hdfs_plugin.install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
              """
              code_skipped: 1 
            @call 
              if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
              handler: ->
                @each files, (options, cb) ->
                  file = options.key
                  target = "#{hdfs.nn.conf_dir}/#{file}"
                  @fs.exists target, (err, exists) ->
                    return cb err if err
                    return cb() unless exists
                    files_exists["#{file}"] = exists
                    properties.read options.ssh, target , (err, props) ->
                      return cb err if err
                      sources_props["#{file}"] = props  
                      cb()   
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
              shy: true
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
            @hconfigure
              header: 'JAAS Properties for solr'
              target: "#{hdfs.nn.conf_dir}/ranger-hdfs-audit.xml"
              merge: true
              properties: ranger.hdfs_plugin.audit
            @each files, (options, cb) ->
              file = options.key
              target = "#{hdfs.nn.conf_dir}/#{file}"
              @fs.exists target, (err, exists) ->
                return callback err if err
                properties.read options.ssh, target , (err, props) ->
                  return cb err if err
                  current_props["#{file}"] = props
                  cb()                
            @call
              header: 'Compare Current Config Files'
              shy: true
              handler: ->
                for file in files
                  #do not need to go further if the file did not exist
                  return callback null, true unless sources_props["#{file}"]?
                  for prop, value of current_props["#{file}"]
                    return callback null, true unless value is sources_props["#{file}"][prop]
                  for prop, value of sources_props["#{file}"]
                    return callback null, true unless value is current_props["#{file}"][prop]
                  return callback null, false

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    properties = require '../../lib/properties'


[hdfs-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin)
[hdfs-plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java

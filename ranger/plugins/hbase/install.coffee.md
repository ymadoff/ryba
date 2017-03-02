
# Ranger HBase Plugin Install

    module.exports = header: 'Ranger HBase Plugin install', handler: ->
      {ranger, hdfs, hbase, realm, hadoop_group, ssl, core_site} = @config.ryba
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      hdfs_plugin = @contexts('ryba/hadoop/hdfs_nn')[0].config.ryba.ranger.hdfs_plugin
      version= null
      conf_dir = null
      
      @call -> conf_dir = if @config.ryba.hbase_plugin_is_master then hbase.master.conf_dir else hbase.rs.conf_dir

## Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Packages

      @call header: 'Packages', handler: ->
        @system.execute
          header: 'Setup Execution'
          shy:true
          cmd: """
            hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-hbase-plugin"

## Layout

      @system.mkdir
        target: ranger.hbase_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: hbase.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.hbase_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        target: ranger.hbase_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: hbase.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.hbase_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

## HBase Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hbase-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hbase/master')[0].config.host is @config.host 
        header: 'Ranger HBase Repository & audit policy'
        handler:  ->
          hbase_policy =
            name: "hbase-ranger-plugin-audit"
            service: "#{hdfs_plugin.install['REPOSITORY_NAME']}"
            repositoryType:"hdfs"
            description: 'HBase Ranger Plugin audit log policy'
            isEnabled: true
            isAuditEnabled: true
            resources:
              path:
                isRecursive: 'true'
                values: ['/ranger/audit/hbaseRegional','/ranger/audit/hbaseMaster']
                isExcludes: false
            policyItems: [{
              users: ["#{hbase.user.name}"]
              groups: []
              delegateAdmin: true
              accesses:[
                  "isAllowed": true
                  "type": "read"
              ,
                  "isAllowed": true
                  "type": "write"
              ,
                  "isAllowed": true
                  "type": "execute"
              ]
              conditions: []
              }]
          @hdfs_mkdir
            header: 'HBase Master plugin HDFS audit dir'
            target: "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hbaseMaster"
            mode: 0o750
            user: hbase.user.name
            group: hbase.group.name
            unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hbaseMaster"
          @hdfs_mkdir
            header: 'HBase Regionserver plugin HDFS audit dir'
            target: "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hbaseRegional"
            mode: 0o750
            user: hbase.user.name
            group: hbase.group.name
            unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/hbaseRegional"
          @system.execute
            header: 'Ranger Admin Policy'
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST \
              -d '#{JSON.stringify hbase_policy}' \
              -u admin:#{password} \
              \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
            """
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\" -k -X GET  \
              -u admin:#{password} \
              \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/#{hdfs_plugin.install['REPOSITORY_NAME']}/policy/hbase-ranger-plugin-audit\"
            """
          @system.execute
            header: 'Ranger Admin Repository'
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.hbase_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.hbase_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """

## HBase  Plugin Principal

        @krb5.addprinc krb5,
          if: ranger.hbase_plugin.principal
          header: 'Ranger HBase Principal'
          principal: ranger.hbase_plugin.principal
          randkey: true
          password: ranger.hbase_plugin.password

## SSL
The Ranger Plugin does not use theire truststore configuration when using solrJClient.
Must add certificate to JAVA Cacerts file manually.

        @java_keystore_add
          keystore: '/usr/java/default/jre/lib/security/cacerts'
          storepass: 'changeit'
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true

## Plugin Scripts 

      @call ->
        @file.render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of ranger.hbase_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{conf_dir}"
            ,
              match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hbase-client/lib"
          ]
          backup: true
          mode: 0o750
        @call
          header: 'Enable HBase Plugin'
          handler: (options, callback) ->
            files = ['ranger-hbase-audit.xml','ranger-hbase-security.xml','ranger-policymgr-ssl.xml']
            sources_props = {}
            current_props = {}
            files_exists = {}
            @system.execute
              cmd: """
                echo '' | keytool -list \
                -storetype jceks \
                -keystore /etc/ranger/#{ranger.hbase_plugin.install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
              """
              code_skipped: 1 
            @call 
              if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
              handler: ->
                @each files, (options, cb) ->
                  file = options.key
                  target = "#{conf_dir}/#{file}"
                  @fs.exists target, (err, exists) ->
                    return cb err if err
                    return cb() unless exists
                    files_exists["#{file}"] = exists
                    properties.read options.ssh, target , (err, props) ->
                      return cb err if err
                      sources_props["#{file}"] = props  
                      cb()
            @system.execute
              header: 'Script Execution'
              cmd: """
                if /usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh ;
                then exit 0 ;
                else exit 1 ;
                fi;
              """
            @system.execute
              header: "Fix Plugin repository permission"
              cmd: "chown -R #{hbase.user.name}:#{hadoop_group.name} /etc/ranger/#{ranger.hbase_plugin.install['REPOSITORY_NAME']}"
            @hconfigure
              header: 'Fix Plugin security conf'
              target: "#{conf_dir}/ranger-hbase-security.xml"
              merge: true
              properties:
                'ranger.plugin.hbase.policy.rest.ssl.config.file': "#{conf_dir}/ranger-policymgr-ssl.xml"
            @each files, (options, cb) ->
              file = options.key
              target = "#{conf_dir}/#{file}"
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
    mkcmd = require '../../../lib/mkcmd'
    properties = require '../../../lib/properties'

[hbase-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hbase_plugin)
[perms-fix]https://community.hortonworks.com/questions/23717/ranger-solr-on-hdp-234-unable-to-refresh-policies.html

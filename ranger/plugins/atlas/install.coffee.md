
# Ranger Atlas Metadata Server Ranger Plugin Install

    module.exports = header: 'Ranger Atlas Plugin install', handler: ->
      {ranger, atlas, realm, hadoop_group, core_site} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      hdfs_plugin = @contexts('ryba/hadoop/hdfs_nn')[0].config.ryba.ranger.hdfs_plugin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version = null
      #https://mail-archives.apache.org/mod_mbox/incubator-ranger-user/201605.mbox/%3C363AE5BD-D796-425B-89C9-D481F6E74BAF@apache.org%3E

# Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

# Create Atlas Policy for On HDFS Repo

      @call
        if: ranger.atlas_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        header: 'Atlas ranger plugin audit to HDFS'
        handler: ->
          @system.mkdir
            target: ranger.atlas_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
            uid: atlas.user.name
            gid: hadoop_group.name
            mode: 0o0750
          @call
            if: @contexts('ryba/ranger/admin')[0].config.ryba.ranger.plugins.hdfs_enabled
          , ->
            atlas_policy =
              name: "atlas-ranger-plugin-audit"
              service: "#{hdfs_plugin.install['REPOSITORY_NAME']}"
              repositoryType:"hdfs"
              description: 'Atlas Ranger Plugin audit log policy'
              isEnabled: true
              isAuditEnabled: true
              resources:
                path:
                  isRecursive: 'true'
                  values: ['/ranger/audit/atlas']
                  isExcludes: false
              policyItems: [{
                users: ["#{atlas.user.name}"]
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
            @execute
              cmd: """
                curl --fail -H "Content-Type: application/json" -k -X POST \
                -d '#{JSON.stringify atlas_policy}' \
                -u admin:#{password} \
                \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
              """
              unless_exec: """
                curl --fail -H \"Content-Type: application/json\" -k -X GET  \
                -u admin:#{password} \
                \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/#{hdfs_plugin.install['REPOSITORY_NAME']}/policy/atlas-ranger-plugin-audit\"
              """
              code_skippe: 22

# Packages

      @call header: 'Packages', handler: ->
        @execute
          header: 'Setup Execution Version'
          shy:true
          cmd: """
            hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-atlas-plugin"

# Atlas ranger plugin audit to SOLR

      @system.mkdir
        target: ranger.atlas_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: atlas.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.atlas_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

# Atlas Service Repository creation
Matchs step 1 in [atlas plugin configuration][atlas-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/atlas')[0].config.host is @config.host 
        header: 'Ranger Atlas Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H  \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.atlas_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.atlas_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.atlas_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.atlas_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.atlas_plugin.principal
            header: 'Ranger Atlas Principal'
            principal: ranger.atlas_plugin.principal
            randkey: true
            password: ranger.atlas_plugin.password
          @hdfs_mkdir
            header: 'Ranger Audit atlas Layout'
            target: "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/atlas"
            mode: 0o750
            user: atlas.user.name
            group: atlas.user.name
            unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/atlas"

# Plugin Scripts 

      @call ->
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-atlas-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of ranger.atlas_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-atlas-plugin/enable-atlas-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{atlas.conf_dir}"
            ,   
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/atlas-server"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/atlas-server/lib"
          ]
          backup: true
          mode: 0o750
        @call
          header: 'Enable Atlas Plugin'
          handler: (options, callback) ->
            files = ['ranger-atlas-audit.xml','ranger-atlas-security.xml','ranger-policymgr-ssl.xml']
            sources_props = {}
            current_props = {}
            files_exists = {}
            @execute
              cmd: """
                echo '' | keytool -list \
                -storetype jceks \
                -keystore /etc/ranger/#{ranger.atlas_plugin.install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
              """
              code_skipped: 1 
            @call 
              if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
              handler: ->
                @each files, (options, cb) ->
                  file = options.key
                  target = "#{atlas.conf_dir}/#{file}"
                  @fs.exists target, (err, exists) ->
                    return cb err if err
                    return cb() unless exists
                    files_exists["#{file}"] = exists
                    properties.read options.ssh, target , (err, props) ->
                      return cb err if err
                      sources_props["#{file}"] = props
                      cb()
            @execute
              header: 'Script Execution'
              cmd: """
                if /usr/hdp/#{version}/ranger-atlas-plugin/enable-atlas-plugin.sh ;
                then exit 0 ;
                else exit 1 ;
                fi;
              """
            @hconfigure
              header: 'Fix ranger-atlas-security conf'
              target: "#{atlas.conf_dir}/ranger-atlas-security.xml"
              merge: true
              properties:
                'ranger.plugin.atlas.policy.rest.ssl.config.file': "#{atlas.conf_dir}/ranger-policymgr-ssl.xml"
            @system.chown
              header: 'Fix Permissions'
              target: "/etc/ranger/#{ranger.atlas_plugin.install['REPOSITORY_NAME']}/.cred.jceks.crc"
              uid: atlas.user.name
              gid: atlas.group.name
            @hconfigure
              header: 'JAAS Properties for solr'
              target: "#{atlas.conf_dir}/ranger-atlas-audit.xml"
              merge: true
              properties: ranger.atlas_plugin.audit
            @each files, (options, cb) ->
              file = options.key
              target = "#{atlas.conf_dir}/#{file}"
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

[atlas-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_atlas_plugin)

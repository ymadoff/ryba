
# Ranger Solr Cloud on Docker Ranger Plugin Install

    module.exports = header: 'Ranger Solr Plugin install', handler: (options) ->
      return if @config.ryba.ranger_solr_installed
      {solr_cluster} = options
      {ranger, solr, realm, hadoop_group, core_site} = @config.ryba
      ranger_admin_ctx = @contexts('ryba/ranger/admin')[0]
      admin = ranger_admin_ctx.config.ryba.ranger.admin
      {password} = ranger_admin_ctx.config.ryba.ranger.admin
      # @call 'ryba/ranger/plugins/solr_cloud_docker/configure', solr_cluster: solr_cluster
      solr_plugin = solr_cluster.host_config.solr_plugin
      hdfs_plugin = @contexts('ryba/hadoop/hdfs_nn')[0].config.ryba.ranger.hdfs_plugin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version = null

# Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

# Create Solr user for Ranger WEBui

      @system.execute
        cmd: """
        curl --fail -H "Content-Type: application/json"   -k -X POST \
          -d '#{JSON.stringify solr_plugin.ranger_user}' -u admin:#{admin.password} \
          \"#{admin.install['policymgr_external_url']}/service/xusers/secure/users\"
        """
        unless_exec: """
        curl --fail -H "Content-Type: application/json"   -k -X GET \
          -u admin:#{admin.password} \
          \"#{admin.install['policymgr_external_url']}/service/xusers/users/userName/#{solr_plugin.ranger_user.name}\"
        """

# Create Solr Ranger Plugin Policy for On HDFS Repo

      @call
        if: solr_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        header: 'Solr ranger plugin audit to HDFS'
      , ->
        @system.mkdir
          target: solr_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
          uid: solr.user.name
          gid: hadoop_group.name
          mode: 0o0750
        @call
          if: @contexts('ryba/ranger/admin')[0].config.ryba.ranger.plugins.hdfs_enabled
        , ->
          hdfs_target_dir = solr_plugin.install['XAAUDIT.HDFS.HDFS_DIR']
          policy_name = "solr-ranger-plugin-audit-#{options.solr_cluster.name}"
          solr_policy =
            name: policy_name
            service: "#{hdfs_plugin.install['REPOSITORY_NAME']}"
            repositoryType:"hdfs"
            description: "Solr audit log policy for cluster: #{options.solr_cluster.name}"
            isEnabled: true
            isAuditEnabled: true
            resources:
              path:
                isRecursive: 'true'
                values: [hdfs_target_dir]
                isExcludes: false
            policyItems: [{
              users: ["#{solr.user.name}"]
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
          @system.execute
            cmd: """
            curl --fail -H "Content-Type: application/json" -k -X POST \
              -d '#{JSON.stringify solr_policy}' \
              -u admin:#{password} \
              \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
            """
            unless_exec: """
            curl --fail -H \"Content-Type: application/json\" -k -X GET  \
              -u admin:#{password} \
              \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/#{hdfs_plugin.install['REPOSITORY_NAME']}/policy/#{policy_name}\"
            """
            code_skipped: 22
          @hdfs_mkdir
            header: 'Ranger Solr Layout'
            target: "#{hdfs_target_dir}"
            mode: 0o750
            user: solr.user.name
            group: solr.user.name
            unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{hdfs_target_dir}"

# Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution Version'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-solr-plugin"

# Solr ranger plugin audit to SOLR

      @system.mkdir
        target: solr_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: solr.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: solr_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

# Solr Service Repository creation
Matchs step 1 in [Solr plugin configuration][solr-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        header: "Repository creation"
      , ->
        @system.execute
          unless_exec: """
          curl --fail -H  \"Content-Type: application/json\"   -k -X GET  \ 
            -u admin:#{password} \"#{solr_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{solr_plugin.install['REPOSITORY_NAME']}\"
          """
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify solr_plugin.service_repo}' \
            -u admin:#{password} \"#{solr_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
          """

# Plugin Scripts 
The execution of the ranger-solr-plugin-enable script,  slightly differs from other plugins.
Indeed the ranger' lib dir needs to be added to solr's classpath. By default solr
loads the lib directory found in the `SOLR_HOME`.

      @call ->
        @file.render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-solr-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of solr_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
      @system.mkdir
        target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes"
        uid: solr.user.name
        gid: hadoop_group.name
        mode: 0o0750
      @system.mkdir
        target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/lib"
        uid: solr.user.name
        gid: hadoop_group.name
        mode: 0o0750
      @call
        header: 'Enable Solr Plugin'
      , (options, callback) ->
        files = ['ranger-solr-audit.xml','ranger-solr-security.xml','ranger-policymgr-ssl.xml']
        sources_props = {}
        current_props = {}
        files_exists = {}
        @system.execute
          cmd: """
          echo '' | keytool -list \
            -storetype jceks \
            -keystore /etc/ranger/#{solr_plugin.install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
          """
          code_skipped: 1
        @call 
          if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
        , ->
          @each files, (options, cb) ->
            file = options.key
            target = "#{solr_plugin.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/#{file}"
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
          if /usr/hdp/#{version}/ranger-solr-plugin/enable-solr-plugin.sh ;
          then exit 0 ;
          else exit 1 ;
          fi;
          """
        @hconfigure
          header: 'Fix ranger-solr-security conf'
          target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/ranger-solr-security.xml"
          merge: true
          properties:
            'ranger.plugin.solr.policy.rest.ssl.config.file': "/usr/solr-cloud/current/server/solr-webapp/webapp/WEB-INF/classes/ranger-policymgr-ssl.xml"
        @chown
          header: 'Fix Permissions'
          target: "/etc/ranger/#{solr_plugin.install['REPOSITORY_NAME']}/.cred.jceks.crc"
          uid: solr.user.name
          gid: solr.group.name
        @hconfigure
          header: 'JAAS Properties for solr'
          target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/ranger-solr-audit.xml"
          merge: true
          properties: solr_plugin.audit
        @each files, (options, cb) ->
          file = options.key
          target = "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/#{file}"
          @fs.exists target, (err, exists) ->
            return callback err if err
            properties.read options.ssh, target , (err, props) ->
              return cb err if err
              current_props["#{file}"] = props
              cb()
        @call
          header: 'Diff'
          shy: true
        , ->
          for file in files
            #do not need to go further if the file did not exist
            return callback null, true unless sources_props["#{file}"]?
            for prop, value of current_props["#{file}"]
              return callback null, true unless value is sources_props["#{file}"][prop]
            for prop, value of sources_props["#{file}"]
              return callback null, true unless value is current_props["#{file}"][prop]
            return callback null, false
      @system.copy
        source: '/etc/hadoop/conf/core-site.xml'
        target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/core-site.xml"
      @system.copy
        source: '/etc/hadoop/conf/hdfs-site.xml'
        target: "#{solr_cluster.config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes/hdfs-site.xml"
      @system.mkdir
        target:  "#{solr_cluster.config.data_dir}/lib"
      , ->
        @system.execute
          cmd:  """
          version=`hdp-select versions | tail -1`
          lib=`ls /usr/hdp/$version/ranger-solr-plugin/lib`
          for file in $lib ;
            do
              echo "link $file ranger/plugins/solr_cloud_docker/install"
              target="#{solr_cluster.config.data_dir}/lib/$file"
              source="/usr/hdp/$version/ranger-solr-plugin/lib/$file"
              if [ -L "$target" ] || [ -e "$target" ] ;
                then
                  current=`readlink $target`
                  if [ "$source" != "$current" ] ; then
                    rm -f $target ;
                    ln -sf $source $target ;
                  fi
                else
                  rm -f $target;
                  ln -sf $source $target;
              fi
            done;
            echo finished;
            exit 0;
            """
      @call -> @config.ryba.ranger_solr_installed = true

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    properties = require '../../../lib/properties'
    fs = require 'ssh2-fs'

[solr-plugin]:(https://community.hortonworks.com/articles/15159/securing-solr-collections-with-ranger-kerberos.html)

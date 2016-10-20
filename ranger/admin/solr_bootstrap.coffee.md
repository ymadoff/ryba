    
    module.exports = header: 'Ranger Audit Solr Boostrap', handler: ->
      {solr} = @config.ryba 
      ranger =  @contexts('ryba/ranger/admin')[0].config.ryba.ranger
      {password} = ranger.admin
      mode = if ranger.admin.solr_type is 'single' then 'standalone' else ranger.admin.solr_type
      tmp_dir = if mode is 'standalone' then "#{solr.user.home}" else '/tmp'
      return unless ['standalone','cloud','cloud_docker'].indexOf ranger?.admin?.solr_type > -1
      
## Dependencies

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @call once: true, "ryba/solr/#{mode}/start" unless mode is 'cloud_docker'
      @call once: true, "ryba/solr/#{mode}/wait" unless mode is 'cloud_docker'
      @call 
        once: true
        if: mode is 'cloud_docker'
      , ->
          @wait_connect
            servers: for host in ranger.admin.cluster_config.hosts
              host: host, port: ranger.admin.cluster_config.port

## Layout

      @mkdir
        target: "#{solr.user.home}/ranger_audits"
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755

## Prepare ranger_audits Collection/Core
Upload files needed by ranger to display infos. The required layout of the folder
depends on the solr cluster type. The files are provided by hortonworks version of solr
only.That's why there are stored as resource, so they can be use when ryba installs
solr apache version.

      @call  
        if: -> mode is 'standalone'
        header: 'Ranger Collection Solr Standalone'
        handler: ->
          @file.download
            source: "#{__dirname}/../resources/solr/admin-extra.html"
            target: "#{tmp_dir}/ranger_audits/admin-extra.html"
          @file.download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-bottom.html"
            target: "#{tmp_dir}/ranger_audits/admin-extra.menu-bottom.html"
          @file.download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-top.html"
            target: "#{tmp_dir}/ranger_audits/admin-extra.menu-top.html"
          @file.download
            source: "#{__dirname}/../resources/solr/elevate.xml"
            target: "#{tmp_dir}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud
          @file.download
            source: "#{__dirname}/../resources/solr/managed-schema"
            target: "#{tmp_dir}/ranger_audits/managed-schema"
          @file.download
            source: "#{__dirname}/../resources/solr/solrconfig.xml"
            target: "#{tmp_dir}/ranger_audits/solrconfig.xml"
      @call
        if: -> (mode is 'cloud_docker') or (mode is 'cloud')
        handler: ->
          # @file.download
          #   source: "#{__dirname}/../resources/solr/admin-extra.html"
          #   target: "#{tmp_dir}/ranger_audits/conf/admin-extra.html"
          # @file.download
          #   source: "#{__dirname}/../resources/solr/admin-extra.menu-bottom.html"
          #   target: "#{tmp_dir}/ranger_audits/conf/admin-extra.menu-bottom.html"
          # @file.download
          #   source: "#{__dirname}/../resources/solr/admin-extra.menu-top.html"
          #   target: "#{tmp_dir}/ranger_audits/conf/admin-extra.menu-top.html"
        @file.download
          source: "#{__dirname}/../resources/solr/managed-schema"
          target: "#{tmp_dir}/ranger_audits/conf/managed-schema"
        @file.download
          source: "#{__dirname}/../resources/solr/solrconfig.xml"
          target: "#{tmp_dir}/ranger_audits/conf/solrconfig.xml"
      @file.download
        if: -> (mode is 'cloud_docker')
        source: "#{__dirname}/../resources/solr/elevate.xml"
        target: "#{tmp_dir}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud without docker
      @file.download
        if: -> (mode is 'cloud')
        source: "#{__dirname}/../resources/solr/elevate.xml"
        target: "#{tmp_dir}/ranger_audits/elevate.xml" #rem
        
## Create ranger_audits Collection/Core
The solrconfig.xml file corresponding to ranger_audits collection/core is rendered from
the resources, as it is not distributed in the apache community version.
The syntax of the command depends also from the solr type installed.
In solr/standalone core are used, whereas in solr/cloud collections are used.
We manage creating the ranger_audits core/collection in the three modes.

### Solr Standalone

      @execute
        if: mode is 'standalone'
        header: 'Create Ranger Core (standalone)'
        unless_exec: """
        curl -k --fail  \"#{ranger.admin.install['audit_solr_urls'].split(',')[0]}/solr/admin/cores?core=ranger_audits&wt=json\" \
        | grep '\"schema\":\"managed-schema\"'
         """
        cmd: """
          #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_core -c ranger_audits \
          -d  #{solr.user.home}/ranger_audits
          """

### Solr Cloud

      @call
        header: 'Create Ranger Collection (cloud)'
      , ->
        return unless (mode is 'cloud')
        @execute
          cmd: """
            #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_collection -c ranger_audits \
            -d  #{tmp_dir}/ranger_audits
            """
          unless_exec: """
          #{solr[ranger.admin.solr_type]['latest_dir']}/bin/solr healthcheck -c ranger_audits \
          | grep '\"status\":\"healthy\"'
           """

### Solr Cloud On Docker
Note: Could not work based on the docker version you use.

      @call
        if: ranger.admin.solr_type is 'cloud_docker'
        header:'Create Ranger Collection (cloud_docker)'
        handler: ->
          @wait_connect
            host: ranger.admin.cluster_config['master']
            port: ranger.admin.cluster_config['port']
          @docker.cp
            source: "#{tmp_dir}/ranger_audits"
            target: "#{ranger.admin.cluster_config.master_container_name}:/ranger_audits"
          @docker.exec
            container: ranger.admin.cluster_config.master_container_runtime_name
            cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c ranger_audits | grep '\"status\":\"healthy\"'"
            code_skipped: [1]
          @docker.exec
            unless: -> @status -1
            container: ranger.admin.cluster_config.master_container_runtime_name
            cmd: """
              /usr/solr-cloud/current/bin/solr create_collection -c ranger_audits \
              -shards #{@contexts('ryba/solr/cloud_docker').length}  \
              -replicationFactor #{@contexts('ryba/solr/cloud_docker').length} \
              -d #{tmp_dir}/ranger_audits
            """
          @call
            header: 'Create Users and Permissions'
            if: ranger.admin.cluster_config.security.authentication['class'] is 'solr.BasicAuthPlugin'
            handler: ->
              @call 
                header: 'Create Users'
                handler: ->
                  url = "#{ranger.admin.install['audit_solr_urls'].split(',')[0]}/solr/admin/authentication"
                  cmd = 'curl --fail --insecure'
                  cmd += " --user #{ranger.admin.cluster_config.solr_admin_user}:#{ranger.admin.cluster_config.solr_admin_password} "
                  for user in ranger.admin.solr_users
                    @execute
                      cmd: """
                        #{cmd} \
                        #{url} -H 'Content-type:application/json' \
                        -d '#{JSON.stringify('set-user':"#{user.name}":"#{user.secret}")}'
                      """
              @call 
                header: 'Set ACL Users'
                handler: ->
                  url = "#{ranger.admin.install['audit_solr_urls'].split(',')[0]}/solr/admin/authorization"
                  cmd = 'curl --fail --insecure'
                  cmd += " --user #{ranger.admin.cluster_config.solr_admin_user}:#{ranger.admin.cluster_config.solr_admin_password} "
                  for user in ranger.admin.cluster_config.ranger.solr_users
                    new_role = "#{user.name}": ['read','update','admin']
                    @execute
                      cmd: """
                        #{cmd} \
                        #{url} -H 'Content-type:application/json' \
                        -d '#{JSON.stringify('set-user-role': new_role )}'
                      """
                      
[ranger-solr-script]:(https://community.hortonworks.com/questions/29291/ranger-solr-script-create-ranger-audits-collection.html)

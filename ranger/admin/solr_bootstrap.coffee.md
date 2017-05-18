    
    module.exports = header: 'Ranger Audit Solr Boostrap', handler: ->
      {solr} = @config.ryba 
      ranger =  @contexts('ryba/ranger/admin')[0].config.ryba.ranger
      {password} = ranger.admin
      cluster_config = ranger.admin.cluster_config
      [zk_connect,zk_node] = cluster_config.zk_urls.split '/'
      mode = if ranger.admin.solr_type is 'single' then 'standalone' else ranger.admin.solr_type
      tmp_dir = if mode is 'standalone' then "#{solr.user.home}" else '/tmp'
      
## Dependencies

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @call once: true, "ryba/solr/#{mode}/start" unless mode is 'cloud_docker'
      @call once: true, "ryba/solr/#{mode}/wait" unless mode is 'cloud_docker'
      @call 
        once: true
        if: mode is 'cloud_docker'
      , ->
          @connection.wait
            servers: for host in cluster_config.hosts
              host: host, port: cluster_config.port

## Layout

      @system.mkdir
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
      , ->
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
        @file.render
          source: "#{__dirname}/../resources/solr/solrconfig.xml"
          target: "#{tmp_dir}/ranger_audits/solrconfig.xml"
          local: true
          context:
            retention_period: ranger.admin.retention
      @call
        if: -> mode in ['cloud_docker', 'cloud']
      , ->
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
        @file.render
          source: "#{__dirname}/../resources/solr/solrconfig.xml"
          target: "#{tmp_dir}/ranger_audits/conf/solrconfig.xml"
          local: true
          context: retention_period: ranger.admin.retention
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

      @system.execute
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
        @system.execute
          cmd: """
          #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_collection -c ranger_audits \
          -shards #{@contexts('ryba/solr/cloud').length}  \
          -replicationFactor #{@contexts('ryba/solr/cloud').length-1}
          -d  #{tmp_dir}/ranger_audits
          """
          unless_exec: "#{solr[ranger.admin.solr_type]['latest_dir']}/bin/solr healthcheck -c ranger_audits"

### Solr Cloud On Docker
Mounth the ranger_audit collection folder to make it availble to the containers.
Note: Compatible with every version of docker available at this time.

      @call
        if: ranger.admin.solr_type is 'cloud_docker'
        header:'Create Ranger Collection (cloud_docker)'
        retry: 2 #needed whensolr node are slow to start
      , (options) ->
          container = null
          @connection.wait
            host: cluster_config['master']
            port: cluster_config['port']
          @system.execute
            cmd: docker.wrap options, "ps | grep #{ranger.admin.cluster_name.split('_').join('')} | grep #{cluster_config['master']} | awk '{print $1}'"
          , (err, status, stdout) ->
            throw err if err
            container = stdout.trim()
          @call
            header: 'Create Collection'
          , ->
            @docker.exec
              container: container
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c ranger_audits"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              container: container
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c ranger_audits \
                  -shards #{@contexts('ryba/solr/cloud_docker').length}  \
                  -replicationFactor #{@contexts('ryba/solr/cloud_docker').length-1} \
                  -d /ranger_audits
                """
          @call
            header: 'Create Users and Permissions'
            if: cluster_config.security.authentication['class'] is 'solr.BasicAuthPlugin'
          , ->
            @call header: 'Create Users', ->
              url = "#{ranger.admin.install['audit_solr_urls'].split(',')[0]}/solr/admin/authentication"
              cmd = 'curl --fail --insecure'
              cmd += " --user #{cluster_config.solr_admin_user}:#{cluster_config.solr_admin_password} "
              for user in ranger.admin.solr_users
                @system.execute
                  cmd: """
                  #{cmd} \
                    #{url} -H 'Content-type:application/json' \
                    -d '#{JSON.stringify('set-user':"#{user.name}":"#{user.secret}")}'
                  """
            @call header: 'Set ACL Users', ->
              url = "#{ranger.admin.install['audit_solr_urls'].split(',')[0]}/solr/admin/authorization"
              cmd = 'curl --fail --insecure'
              cmd += " --user #{cluster_config.solr_admin_user}:#{cluster_config.solr_admin_password} "
              for user in cluster_config.ranger.solr_users
                new_role = "#{user.name}": ['read','update','admin']
                @system.execute
                  cmd: """
                  #{cmd} \
                    #{url} -H 'Content-type:application/json' \
                    -d '#{JSON.stringify('set-user-role': new_role )}'
                  """

## Zookeeper Znode ACL

      @system.execute
        header: 'Zookeeper SolrCloud Znode ACL'
        unless_exec: mkcmd.solr @, """
        zookeeper-client -server #{zk_connect} \
          getAcl /#{zk_node} | grep \"'sasl,'#{solr.user.name}\"
        """
        cmd: mkcmd.solr @, """
        zookeeper-client -server #{zk_connect} \
          setAcl /#{zk_node} sasl:#{solr.user.name}:cdrwa
        """

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    docker = require 'nikita/lib/misc/docker'
    
[ranger-solr-script]:(https://community.hortonworks.com/questions/29291/ranger-solr-script-create-ranger-audits-collection.html)

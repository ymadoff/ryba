    
    module.exports = header: 'Ranger Audit Solr Boostrap', handler: ->
      {ranger, hdfs, yarn, realm, hadoop_group, core_site, solr} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      mode = if ranger.admin.solr_type is 'single' then 'standalone' else ranger.admin.solr_type
      version=null
      tmp_dir = if mode is 'standalone' then "#{solr.user.home}" else '/tmp'
      protocol = if solr[ranger.admin.solr_type].ssl.enabled then 'https' else 'http'
      return unless ['standalone','cloud','cloud_docker'].indexOf ranger.admin.solr_type > -1
      
## Dependencies

      @call once: true, "ryba/solr/#{mode}/start" unless mode is 'cloud_docker'
      @call once: true, "ryba/solr/#{mode}/wait" unless mode is 'cloud_docker'
      @call once: true, 'ryba/ranger/admin/wait'
      @register 'hconfigure', 'ryba/lib/hconfigure'


## Layout

      @mkdir
        destination: "#{solr.user.home}/ranger_audits"
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
        handler: ->
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.html"
            destination: "#{tmp_dir}/ranger_audits/admin-extra.html"
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-bottom.html"
            destination: "#{tmp_dir}/ranger_audits/admin-extra.menu-bottom.html"
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-top.html"
            destination: "#{tmp_dir}/ranger_audits/admin-extra.menu-top.html"
          @download
            source: "#{__dirname}/../resources/solr/elevate.xml"
            destination: "#{tmp_dir}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud
          @download
            source: "#{__dirname}/../resources/solr/managed-schema"
            destination: "#{tmp_dir}/ranger_audits/managed-schema"
          @download
            source: "#{__dirname}/../resources/solr/solrconfig.xml"
            destination: "#{tmp_dir}/ranger_audits/solrconfig.xml"
        if: -> (mode is 'cloud_docker') or (mode is 'cloud')
        handler: ->
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.html"
            destination: "#{tmp_dir}/ranger_audits/conf/admin-extra.html"
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-bottom.html"
            destination: "#{tmp_dir}/ranger_audits/conf/admin-extra.menu-bottom.html"
          @download
            source: "#{__dirname}/../resources/solr/admin-extra.menu-top.html"
            destination: "#{tmp_dir}/ranger_audits/conf/admin-extra.menu-top.html"
          @download
            source: "#{__dirname}/../resources/solr/elevate.xml"
            destination: "#{tmp_dir}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud
          @download
            source: "#{__dirname}/../resources/solr/managed-schema"
            destination: "#{tmp_dir}/ranger_audits/conf/managed-schema"
          @download
            source: "#{__dirname}/../resources/solr/solrconfig.xml"
            destination: "#{tmp_dir}/ranger_audits/conf/solrconfig.xml"
        
## Create ranger_audits Collection/Core
The solrconfig.xml file corresponding to ranger_audits coll/core is rendered from
the resources, as it is not distributed in the apache community version.
The syntax of the command depends also from the solr type installed.
In solr/standalone core are used, whereas in solr/cloud collection are used.
We do not support creating solr/cloud_docker collection for now.

      @execute
        if: -> mode is 'standalone'
        header: 'Create Ranger audit Core'
        unless_exec: """
        curl -k --fail  \"https://#{@config.host}:#{solr[ranger.admin.solr_type]['port']}/solr/admin/cores?core=ranger_audits&wt=json\" \
        | grep '\"schema\":\"managed-schema\"'
         """
        cmd: """
          #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_core -c ranger_audits \
          -d  #{solr.user.home}/ranger_audits
          """
      @execute
        if: -> mode is 'cloud'
        header: 'Create Ranger audit Collection'
        unless_exec: """
        #{solr[ranger.admin.solr_type]['latest_dir']}/bin/solr healthcheck -c ranger_audits \
        | grep '\"status\":\"healthy\"'
         """
        cmd: """
          #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_collection -c ranger_audits \
          -d  #{tmp_dir}/ranger_audits
          """
      @call
        if: ranger.admin.solr_type is 'cloud_docker'
        header: 'Add Ranger plugin user'
        handler: ->
          url = "#{protocol}://#{ranger.admin.cluster_config.hosts[0]}:#{ranger.admin.install['audit_solr_port']}/solr/admin/authentication"
          cmd = 'curl --fail --insecure'
          cmd += " --user #{ranger.admin.cluster_config.ranger.solr_admin_user}:#{ranger.admin.cluster_config.ranger.solr_admin_password} "
          for user in ranger.admin.cluster_config.ranger.solr_users
            cmd = """
              #{cmd} \
              #{url} -H 'Content-type:application/json' \
              -d '#{JSON.stringify('set-user':"#{user.name}":"#{user.secret}")}'
            """
            @execute
              cmd: cmd
      @call 
        if: ranger.admin.solr_type is 'cloud_docker'
        handler: ->
          url = "#{protocol}://#{ranger.admin.cluster_config.hosts[0]}:#{ranger.admin.install['audit_solr_port']}/solr/admin/authorization"
          cmd = 'curl --fail --insecure'
          cmd += " --user #{ranger.admin.cluster_config.ranger.solr_admin_user}:#{ranger.admin.cluster_config.ranger.solr_admin_password} "
          for user in ranger.admin.cluster_config.ranger.solr_users
            new_role = "#{user.name}": ['read','update','admin']
            @execute
              cmd: """
                #{cmd} \
                #{url} -H 'Content-type:application/json' \
                -d '#{JSON.stringify('set-user-role': new_role )}'
              """
      
[ranger-solr-script]:(https://community.hortonworks.com/questions/29291/ranger-solr-script-create-ranger-audits-collection.html)

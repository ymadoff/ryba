
    module.exports = header: 'Ranger Solr Audit Log Bootstrap Plugin install', handler: ->
      {ranger, hdfs, yarn, realm, hadoop_group, core_site, solr} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      mode = if ranger.admin.solr_type is 'single' then 'standalone' else 'cloud'
      version=null

## Dependencies

      @call once: true, "ryba/solr/#{mode}/start" 
      @call once: true, "ryba/solr/#{mode}/wait"
      @call once: true, 'ryba/ranger/admin/wait'
      @register 'hconfigure', 'ryba/lib/hconfigure'

## Layout

      @mkdir
        destination: "#{solr.user.home}/ranger_audits"
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755

## Prepare ranger_audits Collection/Core

      @download
        source: "#{__dirname}/../resources/solr/admin-extra.html"
        destination: "#{solr.user.home}/ranger_audits/admin-extra.html"
      @download
        source: "#{__dirname}/../resources/solr/admin-extra.menu-bottom.html"
        destination: "#{solr.user.home}/ranger_audits/admin-extra.menu-bottom.html"
      @download
        source: "#{__dirname}/../resources/solr/admin-extra.menu-top.html"
        destination: "#{solr.user.home}/ranger_audits/admin-extra.menu-top.html"
      @download
        source: "#{__dirname}/../resources/solr/elevate.xml"
        destination: "#{solr.user.home}/ranger_audits/conf/elevate.xml"
      @download
        source: "#{__dirname}/../resources/solr/managed-schema"
        destination: "#{solr.user.home}/ranger_audits/managed-schema"

## Create ranger_audits Collection/Core
The solrconfig.xml file corresponding to ranger_audits coll/core is rendered from
the resources, as it is not distributed in the apache community version.

      @download
        source: "#{__dirname}/../resources/solr/solrconfig.xml"
        destination: "#{solr.user.home}/ranger_audits/solrconfig.xml"
      @execute
        if: mode is 'standalone'
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
        if: mode is 'cloud'
        header: 'Create Ranger audit Collection'
        unless_exec: """
        #{solr[ranger.admin.solr_type]['latest_dir']}/bin/solr healthcheck -c ranger_audits \
        | grep '\"status\":\"healthy\"'
         """
        cmd: """
          #{solr["#{ranger.admin.solr_type}"]['latest_dir']}/bin/solr create_collection -c ranger_audits \
          -d  #{solr.user.home}/ranger_audits
          """

[ranger-solr-script]:(https://community.hortonworks.com/questions/29291/ranger-solr-script-create-ranger-audits-collection.html)

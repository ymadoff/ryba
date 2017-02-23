
# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin install', handler: ->
      return unless @contexts('ryba/ranger/admin')[0]?
      return unless @contexts('ryba/hadoop/hdfs_nn')[0].config.host is @config.host
      {ranger, hdfs, hadoop_group, realm, ssl_server} = @config.ryba
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version=null

## HDFS Dependencies

      @call 'ryba/ranger/admin/wait'

## HDFS Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hdfs-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hadoop/hdfs_nn')[0].config.host is @config.host 
        header: 'Ranger HDFS Repository'
        handler:  ->
          @system.execute
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

[hdfs-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin)
[hdfs-plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java

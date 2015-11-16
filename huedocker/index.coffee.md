
# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
Starting from 3.7 Hue version
configuring hue following HDP [instructions][hdp-2.3.2.0-hue]

This module should be installed after having executed the prepare script.
It will build and copy to /ryba/huedocker/resources the hue.tar docker image to
beloaded to the target server
```
./bin/prepare
```


    module.exports = []

## Configure

*   `hdp.hue.ini.desktop.database.admin_username` (string)
    Database admin username used to create the Hue database user.
*   `hdp.hue.ini.desktop.database.admin_password` (string)
    Database admin password used to create the Hue database user.
*   `hue.ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue.ini" file.
*   `hue.user` (object|string)
    The Unix Hue login name or a user object (see Mecano User documentation).
*   `hue.group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "hue: {
      "user": {
        "name": "hue", "system": true, "gid": "hue",
        "comment": "Hue User", "home": "/usr/lib/hue"
      },
      "group": {
        "name": "Hue", "system": true
      },
      "ini": {
        "desktop": {
          "database":
            "engine": "mysql"
            "password": "hue123"
          "custom": {
            banner_top_html: "HADOOP : PROD"
          }
        }
      },
      banner_style: 'color:white;text-align:center;background-color:red;',
      clean_tmp: false
    }
  }
}
```

[hbase-configuration]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure
      require('../hadoop/core').configure ctx
      require('../hadoop/hdfs_client').configure ctx
      require('../hadoop/yarn_client').configure ctx
      require('../hive/client').configure ctx
      ryba = ctx.config.ryba ?= {}
      {hadoop_conf_dir, webhcat, db_admin, core_site, hdfs, yarn, hbase} = ryba
      hue = ctx.config.ryba.hue ?= {}
      # Layout
      hue.conf_dir ?= '/etc/hue/conf'
      hue.log_dir ?= '/var/log/hue'
      # Production container image name
      hue.version ?= '3.9'
      hue.image ?= 'ryba/hue'
      hue.container ?= 'hue_server'
      hue.port ?= '8888'
      blacklisted_app = []
      # User
      hue.user ?= {}
      hue.user = name: hue.user if typeof hue.user is 'string'
      hue.user.name ?= 'hue'
      hue.user.uid ?= '2410'
      hue.user.system ?= true
      hue.user.comment ?= 'Hue User'
      hue.user.home = '/var/lib/hue'
      # Group
      hue.group = name: hue.group if typeof hue.group is 'string'
      hue.group ?= {}
      hue.group.name ?= 'hue'
      hue.group.system ?= true
      hue.user.gid = hue.group.name
      hue.clean_tmp ?= true
      hdfs_ctxs = ctx.contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hue.hosts'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hue.groups'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hcat.groups'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hcat.hosts'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.httpfs.groups'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.httpfs.hosts'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hbase.groups'] ?= '*'
        hdfs_ctx.config.ryba.core_site['hadoop.proxyuser.hbase.hosts'] ?= '*'
      oozie_ctxs = ctx.contexts 'ryba/oozie/server'
      for oozie_ctx in oozie_ctxs
        oozie_ctx.config.ryba ?= {}
        oozie_ctx.config.ryba.oozie ?= {}
        oozie_ctx.config.ryba.oozie.site ?= {}
        oozie_ctx.config.ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.hosts'] ?= '*'
        oozie_ctx.config.ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.groups'] ?= '*'
      httpfs_ctxs = ctx.contexts 'ryba/hadoop/httpfs'
      for httpfs_ctx in httpfs_ctxs
        httpfs_ctx.config.ryba ?= {}
        httpfs_ctx.config.ryba.httpfs ?= {}
        httpfs_ctx.config.ryba.httpfs.site ?= {}
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue.user.name}.hosts"] ?= '*'
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue.user.name}.groups"] ?= '*'

      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn'

      hue.ini ?= {}
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ryba.hdfs.site['dfs.webhdfs.enabled'] isnt 'true'
      hue.ca_bundle ?= '/etc/hue/conf/trust.pem'
      hue.ssl ?= {}
      hue.ssl.client_ca ?= null
      throw Error "Property 'hue.ssl.client_ca' required in HA with HTTPS" if nn_ctxs.length > 1 and ryba.hdfs.site['dfs.http.policy'] is 'HTTPS_ONLY' and not hue.ssl.client_ca
      # HDFS & YARN url
      # NOTE: default to unencrypted HTTP
      # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html

      hue.ini['hadoop'] ?= {}
      # Hue Install defines a dependency on HDFS client
      nn_protocol = if ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nn_protocol = 'http' if ryba.hdfs.site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not hue.ssl_client_ca

      if ryba.hdfs.site['dfs.ha.automatic-failover.enabled'] is 'true'
        nn_host = ryba.active_nn_host
        shortname = ctx.contexts(hosts: nn_host)[0].config.shortname
        nn_http_port = ryba.hdfs.site["dfs.namenode.#{nn_protocol}-address.#{ryba.nameservice}.#{shortname}"].split(':')[1]
        webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      else
        nn_host = nn_ctxs[0].config.host
        nn_http_port = ryba.hdfs.site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
        webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"

      # YARN ResourceManager (MR2 Cluster)
      hue.ini['hadoop']['yarn_clusters'] = {}
      hue.ini['hadoop']['yarn_clusters']['default'] ?= {}
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      rm_host = if rm_hosts.length > 1 then ryba.yarn.active_rm_host else  rm_hosts[0]
      throw Error "No YARN ResourceManager configured" unless rm_ctxs.length
      yarn_api_url = []
      # Support for RM HA was added in Hue 3.7
      if rm_hosts.length > 1
        # Active RM
        rm_ctx = ctx.context rm_host, require('../hadoop/yarn_rm').configure
        rm_port = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address.#{rm_ctx.config.shortname}"].split(':')[1]
        yarn_api_url[0] = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site["yarn.resourcemanager.webapp.http.address.#{rm_ctx.config.shortname}"]}"
        else "https://#{yarn.site["yarn.resourcemanager.webapp.https.address.#{rm_ctx.config.shortname}"]}"

        # Standby RM
        rm_host_ha = rm_hosts[1]
        rm_ctx_ha = ctx.context rm_host_ha, require('../hadoop/yarn_rm').configure
        rm_port_ha = rm_ctx_ha.config.ryba.yarn.site["yarn.resourcemanager.address.#{rm_ctx_ha.config.shortname}"].split(':')[1]
        yarn_api_url[1] = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site["yarn.resourcemanager.webapp.http.address.#{rm_ctx_ha.config.shortname}"]}"
        else "https://#{yarn.site["yarn.resourcemanager.webapp.https.address.#{rm_ctx_ha.config.shortname}"]}"

        # hue.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
        hue.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{rm_ctx.config.shortname}"

        # The [[ha]] section contains the 2nd YARN_RM information when HA is enabled
        hue.ini['hadoop']['yarn_clusters']['ha'] ?= {}
        hue.ini['hadoop']['yarn_clusters']['ha']['submit_to'] ?= "true"
        hue.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_api_url'] ?= "#{yarn_api_url[1]}"
        hue.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_port'] ?= "#{rm_port_ha}"
        hue.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{rm_ctx_ha.config.shortname}"
        # hue.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
      else
        rm_ctx = ctx.context rm_host, require('../hadoop/yarn_rm').configure
        rm_port = rm_ctx.config.ryba.yarn.site['yarn.resourcemanager.address'].split(':')[1]
        yarn_api_url[0] = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site['yarn.resourcemanager.webapp.http.address']}"
        else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"

      hue.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}"
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}"
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= "#{yarn_api_url[0]}"
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/hdp/current/hadoop-mapreduce-client'


      # Configure HDFS Cluster
      hue.ini['hadoop']['hdfs_clusters'] ?= {}
      hue.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      hue.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      hue.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= webhdfs_url
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # JobHistoryServer
      jhs_ctx = ctx.contexts('ryba/hadoop/mapred_jhs')[0]
      jhs_protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP' then 'http' else 'https'
      jhs_port = if jhs_protocol is 'http'
      then jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      else jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      hue.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "#{jhs_protocol}://#{jhs_ctx.config.host}:#{jhs_port}"

      # Configure components
      # Oozie
      hue.ini['liboozie'] ?= {}
      hue.ini['liboozie']['oozie_url'] ?= ryba.oozie.site['oozie.base.url']
      hue.ini['hcatalog'] ?= {}
      hue.ini['hcatalog']['templeton_url'] ?= templeton_url
      hue.ini['beeswax'] ?= {}
      # WebHcat
      [webhcat_ctx] = ctx.contexts 'ryba/hive/webhcat', require('../hive/webhcat').configure
      if webhcat_ctx
        webhcat_port = webhcat_ctx.config.ryba.webhcat.site['templeton.port']
        templeton_url = "http://#{webhcat_ctx.config.host}:#{webhcat_port}/templeton/v1/"
      webhcat_ctxs = ctx.contexts 'ryba/hive/webhcat'
      if webhcat_ctxs.length
        for webhcat_ctx in webhcat_ctxs
          webhcat_ctx.config.ryba.webhcat.site['webhcat_ctxs'] ?= '*'
          webhcat_ctx.config.ryba.webhcat.site['webhcat.proxyuser.hue.groups'] ?= '*'
      else
        blacklisted_app.push 'webhcat'
      # HCatalog
      [hs2_ctx] = ctx.contexts 'ryba/hive/server2', require('../hive/server2').configure
      throw Error "No Hive HCatalog Server configured" unless hs2_ctx
      hue.ini['beeswax']['hive_server_host'] ?= "#{hs2_ctx.config.host}"
      hue.ini['beeswax']['hive_server_port'] ?= if hs2_ctx.config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
      then hs2_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      else hs2_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      hue.ini['beeswax']['hive_conf_dir'] ?= "#{ctx.config.ryba.hive.conf_dir}" # Hive client is a dependency of Hue
      hue.ini['beeswax']['server_conn_timeout'] ?= "240"
      # Desktop
      hue.ini['desktop'] ?= {}
      hue.ini['desktop']['django_debug_mode'] ?= '0' # Disable debug by default
      hue.ini['desktop']['http_500_debug_mode'] ?= '0' # Disable debug by default
      hue.ini['desktop']['http'] ?= {}
      hue.ini['desktop']['http_host'] ?= '0.0.0.0'
      hue.ini['desktop']['http_port'] ?= hue.port
      hue.ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue.ini['desktop']['ssl_certificate'] ?= if hue.ssl then '/etc/hue/conf/cert.pem' else null
      hue.ini['desktop']['ssl_private_key'] ?= if hue.ssl then '/etc/hue/conf/key.pem' else null
      hue.ini['desktop']['smtp'] ?= {}
      # From Hue 3.7 ETC has become Etc
      hue.ini['desktop']['time_zone'] ?= 'Etc/UCT'
      hue.ini.desktop.database ?= {}
      hue.ini.desktop.database.user ?= 'hue'
      hue.ini.desktop.database.password ?= 'hue123'
      hue.ini.desktop.database.name ?= 'hue3'
      # Desktop database
      hue.ini['desktop']['database'] ?= {}
      hue.ini['desktop']['database']['engine'] ?= db_admin.engine
      hue.ini['desktop']['database']['host'] ?= db_admin.host
      hue.ini['desktop']['database']['port'] ?= db_admin.port
      hue.ini['desktop']['database']['user'] ?= hue.ini.desktop.database.user
      hue.ini['desktop']['database']['password'] ?= hue.ini.desktop.database.password
      hue.ini['desktop']['database']['name'] ?= hue.ini.desktop.database.name
      # Kerberos
      hue.ini.desktop.kerberos ?= {}
      hue.ini.desktop.kerberos.hue_keytab ?= '/etc/hue/conf/hue.service.keytab'
      hue.ini.desktop.kerberos.hue_principal ?= "hue/#{ctx.config.host}@#{ryba.realm}"
      # Path to kinit
      # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
      # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit
      hue.ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
      # setting cache_name
      hue.ini['desktop']['kerberos']['ccache_path'] ?= "/tmp/krb5cc_#{hue.user.uid}"
      # Remove unused module
      blacklisted_app.push 'rdbms'
      blacklisted_app.push 'impala'
      blacklisted_app.push 'sqoop'
      blacklisted_app.push 'sentry'
      # Sqoop
      sqoop_hosts = ctx.hosts_with_module 'ryba/sqoop'

      # HBase
      # Configuration for Hue version > 3.8.1 (July 2015)
      # Hue communicates with hbase throught the thrift server from Hue 3.7 version
      # Hbase has to be configured to offer impersonation
      # http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
      hbase_thrift_ctxs = ctx.contexts 'ryba/hbase/thrift', require('../hbase/thrift').configure
      if hbase_thrift_ctxs.length
        hbase_thrift_cluster = ''
        for key, hbase_ctx of hbase_thrift_ctxs
          host_adress = ''
          # from source code the hostname should be prefixed with https to warn hue that SSL is enabled
          # activating ssl make hue mismatch fully qualified hostname
          # for now not prefixing anything
          # host_adress += 'https' if hbase_ctx.config.ryba.hbase.site['hbase.thrift.ssl.enabled'] and hbase_ctx.config.ryba.hbase.site['hbase.regionserver.thrift.http']
          host_adress += '' if hbase_ctx.config.ryba.hbase.site['hbase.thrift.ssl.enabled'] and hbase_ctx.config.ryba.hbase.site['hbase.regionserver.thrift.http']
          host_adress += "#{hbase_ctx.config.host}:#{hbase_ctx.config.ryba.hbase.site['hbase.thrift.port']}"
          hbase_thrift_cluster +=  if key == '0' then "(Cluster|#{host_adress})" else ",(Cluster|https://#{host_adress})"
        hue.ini['hbase'] ?= {}
        hue.ini['hbase']['hbase_conf_dir'] ?= hbase.conf_dir
        hue.ini['hbase']['hbase_clusters'] ?= hbase_thrift_cluster
        # Hard limit of rows or columns per row fetched before truncating.
        hue.ini['hbase']['truncate_limit'] ?= '500'
        # use_doas says that HBASE THRIFT uses http in order to enable impersonation
        # set to false if you want to unable
        # not stable
        hue.ini['hbase']['use_doas'] = if hbase_thrift_ctxs[0].config.ryba.hbase.site['hbase.regionserver.thrift.http'] then 'true' else 'false'
        hue.ini['hbase']['thrift_transport'] =  hbase_ctx.config.ryba.hbase.site['hbase.regionserver.thrift.framed']
      else
        blacklisted_app.push 'hbase'


      # Zookeeper
      # for now we do not support zookeeper rest interface
      # zookeeper_ctxs = ctx.contexts ['ryba/zookeeper/server']
      # if zookeeper_ctxs.length
      #   zookeeper_hosts = ''
      #   zookeeper_hosts += ( if key == 0 then "#{zk_ctx.config.host}:#{zk_ctx.config.r}" else ",#{zk_ctx.config.host}:#{zk_ctx.port}") for zk_ctx, key  in zookeeper_ctxs
      # hue.ini['clusters']['default']['host_ports'] ?= zookeeper_hosts
      # hue.ini['clusters']['default']['rest_url'] ?= 'http://example:port'
      # else
      #   blacklisted_app.push 'zookeeper'
      blacklisted_app.push 'zookeeper'
      blacklisted_app.push 'spark'
      # Uncomment all security_enabled settings and set them to true
      hue.ini.hadoop ?= {}
      hue.ini.hadoop.hdfs_clusters ?= {}
      hue.ini.hadoop.hdfs_clusters.default ?= {}
      hue.ini.hadoop.hdfs_clusters.default.security_enabled = 'true'
      # Disabled for yarn cluster , mapreduce job are submitted to yarn
      # hue.ini.hadoop.mapred_clusters ?= {}
      # hue.ini.hadoop.mapred_clusters.default ?= {}
      # hue.ini.hadoop.mapred_clusters.default.security_enabled = 'true'
      # hue.ini.hadoop.mapred_clusters.default.jobtracker_host = "#{rm_host}"
      # hue.ini.hadoop.mapred_clusters.default.jobtracker_port = "#{rm_port}"
      hue.ini.hadoop.yarn_clusters ?= {}
      hue.ini.hadoop.yarn_clusters.default ?= {}
      hue.ini.hadoop.yarn_clusters.default.security_enabled = 'true'
      hue.ini.liboozie ?= {}
      hue.ini.liboozie.security_enabled = 'true'
      hue.ini.hcatalog ?= {}
      hue.ini.hcatalog.security_enabled = 'true'
      hue.ini['desktop']['app_blacklist'] ?= blacklisted_app.join()

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/huedocker/backup'

    module.exports.push commands: 'check', modules: 'ryba/huedocker/check'

    module.exports.push commands: 'install', modules: [
      'ryba/huedocker/install'
      'ryba/huedocker/start'
      'ryba/huedocker/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/huedocker/start'
    #
    module.exports.push commands: 'status', modules: 'ryba/huedocker/status'
    #
    module.exports.push commands: 'stop', modules: 'ryba/huedocker/stop'
    
    module.exports.push commands: 'prepare', modules: 'ryba/huedocker/prepare'
    # module.exports.push commands: 'wait', modules: 'ryba/huedocker/wait'

[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)

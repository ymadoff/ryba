
# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
Starting from 3.7 Hue version
configuring hue following HDP [instructions][hdp-2.3.2.0-hue]

This module should be installed after having executed the prepare script.
It will build and copy to /ryba/huedocker/resources the hue_docker.tar docker image to
beloaded to the target server
```
./bin/prepare
```


    module.exports = []

## Configure

*   `hdp.hue_docker.ini.desktop.database.admin_username` (string)
    Database admin username used to create the Hue database user.
*   `hdp.hue_docker.ini.desktop.database.admin_password` (string)
    Database admin password used to create the Hue database user.
*   `hue_docker.ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue_docker.ini" file.
*   `hue_docker.user` (object|string)
    The Unix Hue login name or a user object (see Mecano User documentation).
*   `hue_docker.group` (object|string)
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
      hue_docker = ctx.config.ryba.hue_docker ?= {}
      # Layout
      hue_docker.conf_dir ?= '/etc/hue_docker/conf'
      hue_docker.log_dir ?= '/var/log/hue_docker'
      hue_docker.pid_file ?= '/var/run/hue_docker'
      # Production container image name
      hue_docker.version ?= '3.9'
      hue_docker.image ?= 'ryba/hue'
      hue_docker.container ?= 'hue_server'
      hue_docker.build ?= {}
      hue_docker.build.name ?= 'ryba/hue-build'
      hue_docker.build.dockerfile ?= "#{__dirname}/resources/build/Dockerfile"
      hue_docker.build.directory ?= "#{__dirname}/resources/cache/build" # was '/tmp/ryba/hue-build'
      hue_docker.prod ?= {}
      hue_docker.prod.directory ?= "#{__dirname}/resources/cache/prod"
      hue_docker.port ?= '8888'
      blacklisted_app = []
      # User
      hue_docker.user ?= {}
      hue_docker.user = name: hue_docker.user if typeof hue_docker.user is 'string'
      hue_docker.user.name ?= 'hue'
      hue_docker.user.uid ?= '2410'
      hue_docker.user.system ?= true
      hue_docker.user.comment ?= 'Hue User'
      hue_docker.user.home = '/var/lib/hue_docker'
      # Group
      hue_docker.group = name: hue_docker.group if typeof hue_docker.group is 'string'
      hue_docker.group ?= {}
      hue_docker.group.name ?= 'hue'
      hue_docker.group.system ?= true
      hue_docker.user.gid ?= hue_docker.group.name
      hue_docker.clean_tmp ?= true
      hdfs_ctxs = ctx.contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{hue_docker.user.name}.hosts"] ?= '*'
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{hue_docker.user.name}.groups"] ?= '*'
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
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{hue_docker.user.name}.hosts"] ?= '*'
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{hue_docker.user.name}.groups"] ?= '*'
      httpfs_ctxs = ctx.contexts 'ryba/hadoop/httpfs'
      for httpfs_ctx in httpfs_ctxs
        httpfs_ctx.config.ryba ?= {}
        httpfs_ctx.config.ryba.httpfs ?= {}
        httpfs_ctx.config.ryba.httpfs.site ?= {}
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue_docker.user.name}.hosts"] ?= '*'
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue_docker.user.name}.groups"] ?= '*'

      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn'

      hue_docker.ini ?= {}
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ryba.hdfs.site['dfs.webhdfs.enabled'] isnt 'true'
      hue_docker.ca_bundle ?= "#{hue_docker.conf_dir}/trust.pem"
      hue_docker.ssl ?= {}
      hue_docker.ssl.client_ca ?= null
      throw Error "Property 'hue_docker.ssl.client_ca' required in HA with HTTPS" if nn_ctxs.length > 1 and ryba.hdfs.site['dfs.http.policy'] is 'HTTPS_ONLY' and not hue_docker.ssl.client_ca
      # HDFS & YARN url
      # NOTE: default to unencrypted HTTP
      # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html

      hue_docker.ini['hadoop'] ?= {}
      # Hue Install defines a dependency on HDFS client
      nn_protocol = if ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nn_protocol = 'http' if ryba.hdfs.site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not hue_docker.ssl_client_ca

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
      hue_docker.ini['hadoop']['yarn_clusters'] = {}
      hue_docker.ini['hadoop']['yarn_clusters']['default'] ?= {}
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

        # hue_docker.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
        hue_docker.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{rm_ctx.config.shortname}"

        # The [[ha]] section contains the 2nd YARN_RM information when HA is enabled
        hue_docker.ini['hadoop']['yarn_clusters']['ha'] ?= {}
        hue_docker.ini['hadoop']['yarn_clusters']['ha']['submit_to'] ?= "true"
        hue_docker.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_api_url'] ?= "#{yarn_api_url[1]}"
        hue_docker.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_port'] ?= "#{rm_port_ha}"
        hue_docker.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{rm_ctx_ha.config.shortname}"
        # hue_docker.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
      else
        rm_ctx = ctx.context rm_host, require('../hadoop/yarn_rm').configure
        rm_port = rm_ctx.config.ryba.yarn.site['yarn.resourcemanager.address'].split(':')[1]
        yarn_api_url[0] = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site['yarn.resourcemanager.webapp.http.address']}"
        else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"

      hue_docker.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue_docker.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}"
      hue_docker.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}"
      hue_docker.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= "#{yarn_api_url[0]}"
      hue_docker.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/hdp/current/hadoop-mapreduce-client'


      # Configure HDFS Cluster
      hue_docker.ini['hadoop']['hdfs_clusters'] ?= {}
      hue_docker.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      hue_docker.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      hue_docker.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= webhdfs_url
      hue_docker.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue_docker.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue_docker.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # JobHistoryServer
      jhs_ctx = ctx.contexts('ryba/hadoop/mapred_jhs')[0]
      jhs_protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP' then 'http' else 'https'
      jhs_port = if jhs_protocol is 'http'
      then jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      else jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      hue_docker.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "#{jhs_protocol}://#{jhs_ctx.config.host}:#{jhs_port}"

      # Configure components
      # Oozie
      hue_docker.ini['liboozie'] ?= {}
      hue_docker.ini['liboozie']['oozie_url'] ?= ryba.oozie.site['oozie.base.url']
      hue_docker.ini['hcatalog'] ?= {}
      hue_docker.ini['hcatalog']['templeton_url'] ?= templeton_url
      hue_docker.ini['beeswax'] ?= {}
      # WebHcat
      [webhcat_ctx] = ctx.contexts 'ryba/hive/webhcat', require('../hive/webhcat').configure
      if webhcat_ctx
        webhcat_port = webhcat_ctx.config.ryba.webhcat.site['templeton.port']
        templeton_url = "http://#{webhcat_ctx.config.host}:#{webhcat_port}/templeton/v1/"
      webhcat_ctxs = ctx.contexts 'ryba/hive/webhcat'
      if webhcat_ctxs.length
        for webhcat_ctx in webhcat_ctxs
          webhcat_ctx.config.ryba.webhcat.site['webhcat_ctxs'] ?= '*'
          webhcat_ctx.config.ryba.webhcat.site["webhcat.proxyuser.#{hue_docker.user.name}.users"] ?= '*'
          webhcat_ctx.config.ryba.webhcat.site["webhcat.proxyuser.#{hue_docker.user.name}.groups"] ?= '*'
      else
        blacklisted_app.push 'webhcat'
      # HCatalog
      [hs2_ctx] = ctx.contexts 'ryba/hive/server2', require('../hive/server2').configure
      throw Error "No Hive HCatalog Server configured" unless hs2_ctx
      hue_docker.ini['beeswax']['hive_server_host'] ?= "#{hs2_ctx.config.host}"
      hue_docker.ini['beeswax']['hive_server_port'] ?= if hs2_ctx.config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
      then hs2_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      else hs2_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      hue_docker.ini['beeswax']['hive_conf_dir'] ?= "#{ctx.config.ryba.hive.conf_dir}" # Hive client is a dependency of Hue
      hue_docker.ini['beeswax']['server_conn_timeout'] ?= "240"
      # Desktop
      hue_docker.ini['desktop'] ?= {}
      hue_docker.ini['desktop']['django_debug_mode'] ?= '0' # Disable debug by default
      hue_docker.ini['desktop']['http_500_debug_mode'] ?= '0' # Disable debug by default
      hue_docker.ini['desktop']['http'] ?= {}
      hue_docker.ini['desktop']['http_host'] ?= '0.0.0.0'
      hue_docker.ini['desktop']['http_port'] ?= hue_docker.port
      hue_docker.ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue_docker.ini['desktop']['ssl_certificate'] ?= if hue_docker.ssl then "#{hue_docker.conf_dir}/cert.pem"else null
      hue_docker.ini['desktop']['ssl_private_key'] ?= if hue_docker.ssl then "#{hue_docker.conf_dir}/key.pem" else null
      hue_docker.ini['desktop']['smtp'] ?= {}
      # From Hue 3.7 ETC has become Etc
      hue_docker.ini['desktop']['time_zone'] ?= 'Etc/UCT'
      hue_docker.ini.desktop.database ?= {}
      hue_docker.ini.desktop.database.user ?= 'hue'
      hue_docker.ini.desktop.database.password ?= 'hue123'
      hue_docker.ini.desktop.database.name ?= 'hue3'
      # Desktop database
      hue_docker.ini['desktop']['database'] ?= {}
      hue_docker.ini['desktop']['database']['engine'] ?= db_admin.engine
      hue_docker.ini['desktop']['database']['host'] ?= db_admin.host
      hue_docker.ini['desktop']['database']['port'] ?= db_admin.port
      hue_docker.ini['desktop']['database']['user'] ?= hue_docker.ini.desktop.database.user
      hue_docker.ini['desktop']['database']['password'] ?= hue_docker.ini.desktop.database.password
      hue_docker.ini['desktop']['database']['name'] ?= hue_docker.ini.desktop.database.name
      # Kerberos
      hue_docker.ini.desktop.kerberos ?= {}
      hue_docker.ini.desktop.kerberos.hue_keytab ?= "#{hue_docker.conf_dir}/hue.service.keytab" # was /etc/hue/conf/hue.server.keytab
      hue_docker.ini.desktop.kerberos.hue_principal ?= "#{hue_docker.user.name}/#{ctx.config.host}@#{ryba.realm}" # was hue_docker/#{ctx.config.host}@#{ryba.realm}
      # Path to kinit
      # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
      # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit
      hue_docker.ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
      # setting cache_name
      hue_docker.ini['desktop']['kerberos']['ccache_path'] ?= "/tmp/krb5cc_#{hue_docker.user.uid}"
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
        hue_docker.ini['hbase'] ?= {}
        hue_docker.ini['hbase']['hbase_conf_dir'] ?= hbase.conf_dir
        hue_docker.ini['hbase']['hbase_clusters'] ?= hbase_thrift_cluster
        # Hard limit of rows or columns per row fetched before truncating.
        hue_docker.ini['hbase']['truncate_limit'] ?= '500'
        # use_doas says that HBASE THRIFT uses http in order to enable impersonation
        # set to false if you want to unable
        # not stable
        # force the use of impersonation in hue.ini, it can be read by hue if set inside hbase-site.xml file
        hue_docker.ini['hbase']['use_doas'] = if hbase_thrift_ctxs[0].config.ryba.hbase.site['hbase.regionserver.thrift.http'] then 'true' else 'false'
        hue_docker.ini['hbase']['thrift_transport'] =  hbase_ctx.config.ryba.hbase.site['hbase.regionserver.thrift.framed']
      else
        blacklisted_app.push 'hbase'


      # Zookeeper
      # for now we do not support zookeeper rest interface
      # zookeeper_ctxs = ctx.contexts ['ryba/zookeeper/server']
      # if zookeeper_ctxs.length
      #   zookeeper_hosts = ''
      #   zookeeper_hosts += ( if key == 0 then "#{zk_ctx.config.host}:#{zk_ctx.config.r}" else ",#{zk_ctx.config.host}:#{zk_ctx.port}") for zk_ctx, key  in zookeeper_ctxs
      # hue_docker.ini['clusters']['default']['host_ports'] ?= zookeeper_hosts
      # hue_docker.ini['clusters']['default']['rest_url'] ?= 'http://example:port'
      # else
      #   blacklisted_app.push 'zookeeper'
      blacklisted_app.push 'zookeeper'
      blacklisted_app.push 'spark'
      # Uncomment all security_enabled settings and set them to true
      hue_docker.ini.hadoop ?= {}
      hue_docker.ini.hadoop.hdfs_clusters ?= {}
      hue_docker.ini.hadoop.hdfs_clusters.default ?= {}
      hue_docker.ini.hadoop.hdfs_clusters.default.security_enabled = 'true'
      # Disabled for yarn cluster , mapreduce job are submitted to yarn
      # hue_docker.ini.hadoop.mapred_clusters ?= {}
      # hue_docker.ini.hadoop.mapred_clusters.default ?= {}
      # hue_docker.ini.hadoop.mapred_clusters.default.security_enabled = 'true'
      # hue_docker.ini.hadoop.mapred_clusters.default.jobtracker_host = "#{rm_host}"
      # hue_docker.ini.hadoop.mapred_clusters.default.jobtracker_port = "#{rm_port}"
      hue_docker.ini.hadoop.yarn_clusters ?= {}
      hue_docker.ini.hadoop.yarn_clusters.default ?= {}
      hue_docker.ini.hadoop.yarn_clusters.default.security_enabled = 'true'
      hue_docker.ini.liboozie ?= {}
      hue_docker.ini.liboozie.security_enabled = 'true'
      hue_docker.ini.hcatalog ?= {}
      hue_docker.ini.hcatalog.security_enabled = 'true'
      hue_docker.ini['desktop']['app_blacklist'] ?= blacklisted_app.join()

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
    module.exports.push commands: 'wait', modules: 'ryba/huedocker/wait'

[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)

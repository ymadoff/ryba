
# Hue Configure

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

    module.exports = handler: ->
      ryba = @config.ryba
      hue = @config.ryba.hue ?= {}
      # Layout
      hue.conf_dir ?= '/etc/hue/conf'
      hue.log_dir ?= '/var/log/hue'
      # User
      hue.user ?= {}
      hue.user = name: hue.user if typeof hue.user is 'string'
      hue.user.name ?= 'hue'
      hue.user.system ?= true
      hue.user.comment ?= 'Hue User'
      hue.user.home = '/var/lib/hue'
      # Group
      hue.group = name: hue.group if typeof hue.group is 'string'
      hue.group ?= {}
      hue.group.name ?= hue.user.name
      hue.group.system ?= true
      hue.user.gid = hue.group.name
      hue.clean_tmp ?= true
      ## Configuration for Proxy Users
      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hue.user.name}.hosts"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hue.user.name}.groups"] ?= '*'
      httpfs_ctxs = @contexts 'ryba/hadoop/httpfs'
      for httpfs_ctx in httpfs_ctxs
        httpfs_ctx.config.ryba ?= {}
        httpfs_ctx.config.ryba.httpfs ?= {}
        httpfs_ctx.config.ryba.httpfs.site ?= {}
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue.user.name}.hosts"] ?= '*'
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{hue.user.name}.groups"] ?= '*'
      oozie_ctxs = @contexts 'ryba/oozie/server'
      for oozie_ctx in oozie_ctxs
        oozie_ctx.config.ryba ?= {}
        oozie_ctx.config.ryba.oozie ?= {}
        oozie_ctx.config.ryba.oozie.site ?= {}
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{hue.user.name}.hosts"] ?= '*'
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{hue.user.name}.groups"] ?= '*'
      {hadoop_conf_dir, webhcat, hue, db_admin, core_site, hdfs, yarn} = ryba
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
      hue ?= {}
      hue.ini ?= {}
      # todo, this might not work as expected after ha migration
      nodemanagers = @hosts_with_module 'ryba/hadoop/yarn_nm'
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

      # Hue Install defines a dependency on HDFS client
      nn_protocol = if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nn_protocol = 'http' if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not hue.ssl_client_ca
      if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] is 'true'
        nn_host = nn_ctxs[0].config.ryba.active_nn_host
        shortname = @contexts(hosts: nn_host)[0].config.shortname
        nn_http_port = nn_ctxs[0].config.ryba.hdfs.nn.site["dfs.namenode.#{nn_protocol}-address.#{nn_ctxs[0].config.ryba.nameservice}.#{shortname}"].split(':')[1]
        webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      else
        nn_host = nn_ctxs[0].config.host
        nn_http_port = nn_ctxs[0].config.ryba.hdfs.nn.site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
        webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      # Support for RM HA was added in Hue 3.7
      # rm_protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'

      # rm_hosts = @hosts_with_module 'ryba/hadoop/yarn_rm'
      # if rm_hosts.length > 1
      #   rm_host = ryba.yarn.active_rm_host
      #   rm_ctx = @context rm_host, require('../hadoop/yarn_rm').configure
      #   rm_port = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address.#{rm_ctx.config.shortname}"].split(':')[1]
      #   yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      #   then "http://#{yarn.site['yarn.resourcemanager.webapp.address.#{rm_ctx.config.shortname}']}"
      #   else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address.#{rm_ctx.config.shortname}']}"
      # else
      #   rm_host = rm_hosts[0]
      #   rm_ctx = @context rm_host, require('../hadoop/yarn_rm').configure
      #   rm_port = rm_ctx.config.ryba.yarn.site['yarn.resourcemanager.address'].split(':')[1]
      #   yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      #   then "http://#{yarn.site['yarn.resourcemanager.webapp.address']}"
      #   else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"
      # YARN ResourceManager
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      throw Error "No YARN ResourceManager configured" unless rm_ctxs.length
      is_yarn_ha = rm_ctxs.length > 1
      rm_ctx = rm_ctxs[0]
      yarn_id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
      rm_host = rm_ctx.config.host
      # Strange, "rm_rpc_url" default to "http://localhost:8050" which doesnt make
      # any sense since this isnt http
      rm_rpc_add = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{yarn_id}"]
      rm_rpc_url = "http://#{rm_rpc_add}"
      rm_port = rm_rpc_add.split(':')[1]
      yarn_api_url = if rm_ctx.config.ryba.yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY'
      then "http://#{yarn.site['yarn.resourcemanager.webapp.address']}"
      else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"
      # NodeManager
      [nm_ctx] = @contexts 'ryba/hadoop/yarn_nm', require('../hadoop/yarn_nm').configure
      node_manager_api_url = if @config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      then "http://#{nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.address']}"
      else "https://#{nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.https.address']}"
      # WebHcat
      [webhcat_ctx] = @contexts 'ryba/hive/webhcat', require('../hive/webhcat').configure
      if webhcat_ctx
        webhcat_port = webhcat_ctx.config.ryba.webhcat.site['templeton.port']
        templeton_url = "http://#{webhcat_ctx.config.host}:#{webhcat_port}/templeton/v1/"
      # Configure HDFS Cluster
      hue.ini['hadoop'] ?= {}
      hue.ini['hadoop']['hdfs_clusters'] ?= {}
      hue.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      hue.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      hue.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= webhdfs_url
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # Configure YARN (MR2) Cluster
      hue.ini['hadoop']['yarn_clusters'] ?= {}
      hue.ini['hadoop']['yarn_clusters']['default'] ?= {}
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}" # Might no longer be required after hdp2.2
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}" # Might no longer be required after hdp2.2
      hue.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/hdp/current/hadoop-mapreduce-client'
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= '/usr/hdp/current/hadoop-client/bin/hadoop'
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= yarn_api_url
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_rpc_url'] ?= rm_rpc_url
      hue.ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= yarn_api_url
      hue.ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= node_manager_api_url
      # JHS
      jhs_ctx = @contexts('ryba/hadoop/mapred_jhs')[0]
      jhs_protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP' then 'http' else 'https'
      jhs_port = if jhs_protocol is 'http'
      then jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      else jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      hue.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "#{jhs_protocol}://#{jhs_ctx.config.host}:#{jhs_port}"
      # Configure components
      hue.ini['liboozie'] ?= {}
      hue.ini['liboozie']['oozie_url'] ?= ryba.oozie.site['oozie.base.url']
      hue.ini['hcatalog'] ?= {}
      hue.ini['hcatalog']['templeton_url'] ?= templeton_url
      hue.ini['beeswax'] ?= {}
      # HCatalog
      [hs2_ctx] = @contexts 'ryba/hive/server2', require('../hive/server2').configure
      throw Error "No Hive HCatalog Server configured" unless hs2_ctx
      hue.ini['beeswax']['hive_server_host'] ?= "#{hs2_ctx.config.host}"
      hue.ini['beeswax']['hive_server_port'] ?= if hs2_ctx.config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
      then hs2_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      else hs2_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      # http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html
      if hs2_ctx.config.ryba.hive.site['hive.server2.use.SSL']
        throw Error 'Hue must be configured with ssl if communicating with hive over ssl' unless  hue.ssl.client_ca
        hue.ini['beeswax']['ssl'] ?= {}
        hue.ini['beeswax']['ssl']['enabled'] ?= 'true'
        hue.ini['beeswax']['ssl']['cacerts'] ?= "#{hue.conf_dir}/trust.pem"
        hue.ini['beeswax']['ssl']['cert'] ?= "#{hue.conf_dir}/cert.pem"
        hue.ini['beeswax']['ssl']['key'] ?= "#{hue.conf_dir}/key.pem"
      # Desktop
      hue.ini['desktop'] ?= {}
      hue.ini['desktop']['django_debug_mode'] ?= '0' # Disable debug by default
      hue.ini['desktop']['http_500_debug_mode'] ?= '0' # Disable debug by default
      hue.ini['desktop']['http'] ?= {}
      hue.ini['desktop']['http_host'] ?= '0.0.0.0'
      hue.ini['desktop']['http_port'] ?= '8888'
      hue.ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue.ini['desktop']['smtp'] ?= {}
      hue.ini['desktop']['time_zone'] ?= 'ETC/UTC'
      # Desktop database
      hue.ini['desktop']['database'] ?= {}
      hue.ini['desktop']['database']['engine'] ?= db_admin.engine
      hue.ini['desktop']['database']['host'] ?= db_admin.host
      hue.ini['desktop']['database']['port'] ?= db_admin.port
      hue.ini['desktop']['database']['user'] ?= 'hue'
      hue.ini['desktop']['database']['password'] ?= 'hue123'
      hue.ini['desktop']['database']['name'] ?= 'hue'
      # Kerberos
      hue.ini.desktop.kerberos ?= {}
      hue.ini.desktop.kerberos.hue_keytab ?= '/etc/hue/conf/hue.service.keytab'
      hue.ini.desktop.kerberos.hue_principal ?= "hue/#{@config.host}@#{ryba.realm}"
      # Path to kinit
      # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
      # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit
      hue.ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
      # Uncomment all security_enabled settings and set them to true
      hue.ini.hadoop ?= {}
      hue.ini.hadoop.hdfs_clusters ?= {}
      hue.ini.hadoop.hdfs_clusters.default ?= {}
      hue.ini.hadoop.hdfs_clusters.default.security_enabled = 'true'
      hue.ini.hadoop.mapred_clusters ?= {}
      hue.ini.hadoop.mapred_clusters.default ?= {}
      hue.ini.hadoop.mapred_clusters.default.security_enabled = 'true'
      hue.ini.hadoop.yarn_clusters ?= {}
      hue.ini.hadoop.yarn_clusters.default ?= {}
      hue.ini.hadoop.yarn_clusters.default.security_enabled = 'true'
      hue.ini.liboozie ?= {}
      hue.ini.liboozie.security_enabled = 'true'
      hue.ini.hcatalog ?= {}
      hue.ini.hcatalog.security_enabled = 'true'

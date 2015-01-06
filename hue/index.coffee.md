
## Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
a Zookeeper Browser and a SDK.

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
      banner_style: 'color:white;text-align:center;background-color:red;'
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      # Allow proxy user inside "webhcat-site.xml"
      require('../hive/webhcat').configure ctx
      # Allow proxy user inside "oozie-site.xml"
      require('../oozie/server').configure ctx
      # Allow proxy user inside "core-site.xml"
      require('../hadoop/core').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('../hadoop/yarn').configure ctx
      {ryba} = ctx.config
      {nameservice, hadoop_conf_dir, webhcat_site, hue, db_admin, core_site, hdfs_site, yarn} = ryba
      hdfs_nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      hue ?= {}
      hue.ini ?= {}
      webhcat_port = webhcat_site['templeton.port']
      webhcat_server = ctx.host_with_module 'ryba/hive/webhcat'
      # todo, this might not work as expected after ha migration
      nodemanagers = ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
      jobhistoryserver = ctx.host_with_module 'ryba/hadoop/mapred_jhs'
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ryba.hdfs_site['dfs.webhdfs.enabled'] isnt 'true'
      hue.conf_dir ?= '/etc/hue/conf'
      hue.ca_bundle ?= '/etc/hue/conf/trust.pem'
      hue.ssl ?= {}
      hue.ssl.client_ca ?= null
      throw Error "Property 'hue.ssl.client_ca' required in HA with HTTPS" if hdfs_nn_hosts.length > 1 and hdfs_site['dfs.http.policy'] is 'HTTPS_ONLY' and not hue.ssl.client_ca
      # User
      hue.user ?= {}
      hue.user = name: hue.user if typeof hue.user is 'string'
      hue.user.name ?= 'hue'
      hue.user.system ?= true
      hue.user.gid = 'hue'
      hue.user.comment ?= 'Hue User'
      hue.user.home = '/var/lib/hue'
      # Group
      hue.group = name: hue.group if typeof hue.group is 'string'
      hue.group ?= {}
      hue.group.name ?= 'hue'
      hue.group.system ?= true
      # HDFS & YARN url
      # NOTE: default to unencrypted HTTP
      # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html
      nn_protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nn_protocol = 'http' if hdfs_site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not hue.ssl_client_ca
      if hdfs_nn_hosts.length > 1
        nn_host = ryba.active_nn_host
        shortname = ctx.hosts[nn_host].config.shortname
        nn_http_port = ryba.ha_client_config["dfs.namenode.#{nn_protocol}-address.#{nameservice}.#{shortname}"].split(':')[1]
      else
        nn_host = hdfs_nn_hosts[0]
        nn_http_port = hdfs_site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
      # Support for RM HA was added in Hue 3.7
      rm_protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      if rm_hosts.length > 1
        rm_host = ryba.active_rm_host
        rm_ctx = ctx.context rm_host, require('../hadoop/yarn').configure
        rm_port = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address.#{rm_ctx.config.shortname}"].split(':')[1]
        yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site['yarn.resourcemanager.webapp.address.#{rm_ctx.config.shortname}']}"
        else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address.#{rm_ctx.config.shortname}']}"
      else
        rm_host = rm_hosts[0]
        rm_ctx = ctx.context rm_host, require('../hadoop/yarn').configure
        rm_port = rm_ctx.config.ryba.yarn.site['yarn.resourcemanager.address'].split(':')[1]
        yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{yarn.site['yarn.resourcemanager.webapp.address']}"
        else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"

      # Configure HDFS Cluster
      hue.ini['hadoop'] ?= {}
      hue.ini['hadoop']['hdfs_clusters'] ?= {}
      hue.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      hue.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      hue.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # Configure YARN (MR2) Cluster
      hue.ini['hadoop']['yarn_clusters'] ?= {}
      hue.ini['hadoop']['yarn_clusters']['default'] ?= {}
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}"
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}"
      hue.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/lib/hadoop-mapreduce'
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue.ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= yarn_api_url
      hue.ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= yarn_api_url
      hue.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "http://#{jobhistoryserver}:19888"
      hue.ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= "http://#{nodemanagers[0]}:8042"
      # Configure components
      hue.ini['liboozie'] ?= {}
      hue.ini['liboozie']['oozie_url'] ?= ryba.oozie.site['oozie.base.url']
      hue.ini['hcatalog'] ?= {}
      hue.ini['hcatalog']['templeton_url'] ?= "http://#{webhcat_server}:#{webhcat_port}/templeton/v1/"
      hue.ini['beeswax'] ?= {}
      hue.ini['beeswax']['beeswax_server_host'] ?= "#{ctx.config.host}"
      # Desktop
      hue.ini['desktop'] ?= {}
      hue.ini['desktop']['http'] ?= {}
      hue.ini['desktop']['http']['host'] ?= '0.0.0.0'
      hue.ini['desktop']['http']['port'] ?= '8888'
      hue.ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue.ini['desktop']['smtp'] ?= {}
      ctx.log "WARING: property 'hdp.hue.ini.desktop.smtp.host' isnt set" unless hue.ini['desktop']['smtp']['host']
      # Desktop database
      hue.ini['desktop']['database'] ?= {}
      hue.ini['desktop']['database']['engine'] ?= db_admin.engine
      hue.ini['desktop']['database']['host'] ?= db_admin.host
      hue.ini['desktop']['database']['port'] ?= db_admin.port
      hue.ini['desktop']['database']['user'] ?= 'hue'
      hue.ini['desktop']['database']['password'] ?= 'hue123'
      hue.ini['desktop']['database']['name'] ?= 'hue'

    # module.exports.push commands: 'backup', modules: 'ryba/hue/backup'

    # module.exports.push commands: 'check', modules: 'ryba/hue/check'

    module.exports.push commands: 'install', modules: 'ryba/hue/install'

    module.exports.push commands: 'start', modules: 'ryba/hue/start'

    module.exports.push commands: 'status', modules: 'ryba/hue/status'

    module.exports.push commands: 'stop', modules: 'ryba/hue/stop'

[home]: http://gethue.com



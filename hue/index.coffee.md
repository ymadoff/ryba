
## Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
a Zookeeper Browser and a SDK.

    module.exports = []

## Configure

*   `hdp.hue_db_admin_username` (string)   
    Database admin username used to create the Hue database user.  
*   `hdp.hue_db_admin_password` (string)   
    Database admin password used to create the Hue database user.   
*   `hue.hue_ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue.ini" file.   
*   `hue_user` (object|string)   
    The Unix Hue login name or a user object (see Mecano User documentation).   
*   `hue_group` (object|string)   
    The Unix Hue group name or a group object (see Mecano Group documentation).   

Example:

```json
{
  "hue": {
    "hue_user": {
      "name": "hue", "system": true, "gid": "hue",
      "comment": "Hue User", "home": "/usr/lib/hue"
    }
    "hue_group": {
      "name": "Hue", "system": true
    }
    "hue_ini": {
      "desktop": {
        "database":
          "engine": "mysql"
          "password": "hue123"
      }
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
      {nameservice, hadoop_conf_dir, webhcat_site, hue_ini, db_admin, core_site
        hdfs_site, yarn_site} = ryba
      is_nn_ha = ctx.host_with_module('ryba/hadoop/hdfs_nn').length > 1
      hue_ini ?= ryba.hue_ini = {}
      webhcat_port = webhcat_site['templeton.port']
      webhcat_server = ctx.host_with_module 'ryba/hive/webhcat'
      # todo, this might not work as expected after ha migration
      resourcemanager = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      nodemanagers = ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
      jobhistoryserver = ctx.host_with_module 'ryba/hadoop/mapred_jhs'
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ryba.hdfs_site['dfs.webhdfs.enabled'] isnt 'true'
      ryba.hue_conf_dir ?= '/etc/hue/conf'
      ryba.hue_ca_bundle ?= '/etc/hue/conf/trust.pem'
      ryba.hue_ssl_client_ca ?= null
      throw Error "Property 'hue_ssl_client_ca' required in HA with HTTPS" if is_nn_ha and hdfs_site['dfs.http.policy'] is 'HTTPS_ONLY' and not ryba.hue_ssl_client_ca
      # User
      ryba.hue_user = name: ryba.hue_user if typeof ryba.hue_user is 'string'
      ryba.hue_user ?= {}
      ryba.hue_user.name ?= 'hue'
      ryba.hue_user.system ?= true
      ryba.hue_user.gid = 'hue'
      ryba.hue_user.comment ?= 'Hue User'
      ryba.hue_user.home = '/var/lib/hue'
      # Group
      ryba.hue_group = name: ryba.hue_group if typeof ryba.hue_group is 'string'
      ryba.hue_group ?= {}
      ryba.hue_group.name ?= 'hue'
      ryba.hue_group.system ?= true
      # HDFS & YARN url
      # NOTE: default to unencrypted HTTP
      # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html
      nn_protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nn_protocol = 'http' if hdfs_site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not ryba.hue_ssl_client_ca
      if is_nn_ha
        nn_host = ctx.host_with_module 'ryba/hadoop/hdfs_nn'
        nn_http_port = hdfs_site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
      else
        nn_host = ryba.active_nn_host
        shortname = ctx.hosts[nn_host].config.shortname
        nn_http_port = ryba.ha_client_config["dfs.namenode.#{nn_protocol}-address.#{nameservice}.#{shortname}"].split(':')[1]
      yarn_api_url = if yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
      then "http://#{yarn_site['yarn.resourcemanager.webapp.address']}"
      else "https://#{yarn_site['yarn.resourcemanager.webapp.https.address']}"
      # Configure HDFS Cluster
      hue_ini['hadoop'] ?= {}
      hue_ini['hadoop']['hdfs_clusters'] ?= {}
      hue_ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      hue_ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      hue_ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # Configure YARN (MR2) Cluster
      hue_ini['hadoop']['yarn_clusters'] ?= {}
      hue_ini['hadoop']['yarn_clusters']['default'] ?= {}
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{resourcemanager}"
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "8050"
      hue_ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/lib/hadoop-mapreduce'
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= yarn_api_url
      hue_ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= yarn_api_url
      hue_ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "http://#{jobhistoryserver}:19888"
      hue_ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= "http://#{nodemanagers[0]}:8042"
      # Configure components
      hue_ini['liboozie'] ?= {}
      hue_ini['liboozie']['oozie_url'] ?= ryba.oozie_site['oozie.base.url']
      hue_ini['hcatalog'] ?= {}
      hue_ini['hcatalog']['templeton_url'] ?= "http://#{webhcat_server}:#{webhcat_port}/templeton/v1/"
      hue_ini['beeswax'] ?= {}
      hue_ini['beeswax']['beeswax_server_host'] ?= "#{ctx.config.host}"
      # Desktop
      hue_ini['desktop'] ?= {}
      hue_ini['desktop']['http_host'] ?= '0.0.0.0'
      hue_ini['desktop']['http_port'] ?= '8888'
      hue_ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue_ini['desktop']['smtp'] ?= {}
      ctx.log "WARING: property 'hdp.hue_ini.desktop.smtp.host' isnt set" unless hue_ini['desktop']['smtp']['host']
      # Desktop database
      hue_ini['desktop']['database'] ?= {}
      hue_ini['desktop']['database']['engine'] ?= db_admin.engine
      hue_ini['desktop']['database']['host'] ?= db_admin.host
      hue_ini['desktop']['database']['port'] ?= db_admin.port
      hue_ini['desktop']['database']['user'] ?= 'hue'
      hue_ini['desktop']['database']['password'] ?= 'hue123'
      hue_ini['desktop']['database']['name'] ?= 'hue'

    # module.exports.push commands: 'backup', modules: 'ryba/hue/backup'

    # module.exports.push commands: 'check', modules: 'ryba/hue/check'

    module.exports.push commands: 'install', modules: 'ryba/hue/install'

    module.exports.push commands: 'start', modules: 'ryba/hue/start'

    module.exports.push commands: 'status', modules: 'ryba/hue/status'

    module.exports.push commands: 'stop', modules: 'ryba/hue/stop'

[home]: http://gethue.com



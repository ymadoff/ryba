
# HADOOP YARN NodeManager Install

    module.exports = header: 'YARN NM Install', handler: ->
      {realm, hadoop_group, hadoop_metrics, hadoop_conf_dir, core_site, hdfs, yarn, container_executor} = @config.ryba
      {ssl, ssl_server, ssl_client} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'masson/core/krb5_client/wait'

## IPTables

| Service    | Port | Proto  | Parameter                          |
|------------|------|--------|------------------------------------|
| nodemanager | 45454 | tcp  | yarn.nodemanager.address           | x
| nodemanager | 8040  | tcp  | yarn.nodemanager.localizer.address |
| nodemanager | 8042  | tcp  | yarn.nodemanager.webapp.address    |
| nodemanager | 8044  | tcp  | yarn.nodemanager.webapp.https.address    |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      nm_port = yarn.site['yarn.nodemanager.address'].split(':')[1]
      nm_localizer_port = yarn.site['yarn.nodemanager.localizer.address'].split(':')[1]
      nm_webapp_port = yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
      nm_webapp_https_port = yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Container" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_localizer_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Localizer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web Secured UI" }
        ]
        if: @config.iptables.action is 'start'

## Packages

Install the "hadoop-yarn-nodemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', handler: ->
        @service
          name: 'hadoop-yarn-nodemanager'
        @hdp_select
          name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-nodemanager'
        @render
          destination: '/etc/init.d/hadoop-yarn-nodemanager'
          source: "#{__dirname}/../resources/hadoop-yarn-nodemanager"
          local_source: true
          context: @config
          mode: 0o0755
          unlink: true
        @service # Seems like NM complain with message "java.lang.ClassNotFoundException: Class org.apache.hadoop.mapred.ShuffleHandler not found"
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'
        @execute
          cmd: "service hadoop-yarn-nodemanager restart"
          if: -> @status -3

      @call header: 'Layout', handler: ->
        @mkdir
          destination: "#{yarn.nm.conf_dir}"
        @mkdir
          destination: "#{yarn.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @mkdir
          destination: "#{yarn.log_dir}"
          uid: yarn.user.name
          gid: yarn.group.name
          parent: true
        @mkdir
          destination: yarn.site['yarn.nodemanager.log-dirs'].split ','
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @mkdir
          destination: yarn.site['yarn.nodemanager.local-dirs'].split ','
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @mkdir
          destination: yarn.site['yarn.nodemanager.recovery.dir'] 
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0750
          parent: true

## Capacity Planning

Naive discovery of the memory and CPU allocated by this NodeManager.

It is recommended to use the "capacity" script prior install Hadoop on
your cluster. It will suggest you relevant values for your servers with a
global view of your system. In such case, this middleware is bypassed and has
no effect. Also, this isnt included inside the configuration because it need an
SSH connection to the node to gather the memory and CPU informations.

      @call
        header: 'Capacity Planning'
        unless: yarn.site['yarn.nodemanager.resource.memory-mb'] and yarn.site['yarn.nodemanager.resource.cpu-vcores']
        handler: ->
          # diskNumber = yarn.site['yarn.nodemanager.local-dirs'].length
          yarn.site['yarn.nodemanager.resource.memory-mb'] ?= Math.round @meminfo.MemTotal / 1024 / 1024 * .8
          yarn.site['yarn.nodemanager.resource.cpu-vcores'] ?= @cpuinfo.length

## Configure

      @hconfigure
        header: 'Core Site'
        destination: "#{yarn.nm.conf_dir}/core-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        destination: "#{yarn.nm.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        header: 'YARN Site'
        destination: "#{yarn.nm.conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        backup: true
      @write
        header: 'Log4j'
        destination: "#{yarn.nm.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true
      @render
        header: 'YARN Env'
        destination: "#{yarn.nm.conf_dir}/yarn-env.sh"
        source: "#{__dirname}/../resources/yarn-env.sh.j2"
        local_source: true
        context: @config
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @write_properties
        header: 'Metrics'
        destination: "#{yarn.nm.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## Container Executor

Important: path seems hardcoded to "../etc/hadoop/container-executor.cfg", 
running `/usr/hdp/current/hadoop-yarn-client/bin/container-executor` will print
"Configuration file ../etc/hadoop/container-executor.cfg not found." if missing.

The parent directory must be owned by root or it will print: "Caused by:
ExitCodeException exitCode=24: File File /etc/hadoop/conf must be owned by root,
but is owned by 2401"

      @call header: 'Container Executor', handler: ->
        ce_group = container_executor['yarn.nodemanager.linux-container-executor.group']
        ce = '/usr/hdp/current/hadoop-yarn-nodemanager/bin/container-executor'
        @chown
          destination: ce
          uid: 'root'
          gid: ce_group
        @chmod
          destination: ce
          mode: 0o6050
        @mkdir
          destination: "#{hadoop_conf_dir}"
          uid: 'root'
        @write_ini
          destination: "#{hadoop_conf_dir}/container-executor.cfg"
          content: container_executor
          uid: 'root'
          gid: ce_group
          mode: 0o0640
          separator: '='
          backup: true

## SSL

      @call header: 'SSL', retry: 0, handler: ->
        ssl_client['ssl.client.truststore.location'] = "#{yarn.nm.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{yarn.nm.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{yarn.nm.conf_dir}/truststore"
        @hconfigure
          destination: "#{yarn.nm.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          destination: "#{yarn.nm.conf_dir}/ssl-client.xml"
          properties: ssl_client
        # Client: import certificate to all hosts
        @java_keystore_add
          keystore: ssl_client['ssl.client.truststore.location']
          storepass: ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true
        # Server: import certificates, private and public keys to hosts with a server
        @java_keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local_source: true
        @java_keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true

Create the Kerberos user to the Node Manager service. By default, it takes the
form of "rm/{fqdn}@{realm}"

      @krb5_addprinc
        header: 'Kerberos'
        principal: yarn.site['yarn.nodemanager.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.nodemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

      @call
        header: 'CGroup'
        if: -> yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'true'
        handler: ->
          @service
            name: 'libcgroup'
          # .execute
          #   cmd: 'mount -t cgroup -o cpu cpu /cgroup'
          #   code_skipped: 32
          @mkdir
            destination: "#{yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path']}/cpu"
            mode: 0o1777
            parent: true

## Ulimit

Increase ulimit for the HFDS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/yarn.conf
yarn   - nofile 32768
yarn   - nproc  65536
```

Note, a user must re-login for those changes to be taken into account. See
the "ryba/hadoop/hdfs" module for additional information.

      @system_limits
        header: 'Ulimit'
        user: yarn.user.name
        nofile: yarn.user.limits.nofile
        nproc: yarn.user.limits.nproc

### HDFS Layout

Create the YARN log directory defined by the property 
"yarn.nodemanager.remote-app-log-dir". The default value in the HDP companion
files is "/app-logs". The command `hdfs dfs -ls /` should print:

```
drwxrwxrwt   - yarn   hadoop            0 2014-05-26 11:01 /app-logs
```

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

      remote_app_log_dir = yarn.site['yarn.nodemanager.remote-app-log-dir']
      @execute
        header: 'HDFS layout'
        cmd: mkcmd.hdfs @, """
        hdfs --config #{hdfs.dn.conf_dir} dfs -mkdir -p #{remote_app_log_dir}
        hdfs --config #{hdfs.dn.conf_dir} dfs -chown #{yarn.user.name}:#{hadoop_group.name} #{remote_app_log_dir}
        hdfs --config #{hdfs.dn.conf_dir} dfs -chmod 1777 #{remote_app_log_dir}
        """
        unless_exec: "[[ hdfs dfs -d #{remote_app_log_dir} ]]"
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'

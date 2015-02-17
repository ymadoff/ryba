
# YARN NodeManager Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/info'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/yarn'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./yarn_nm').configure

## IPTables

| Service    | Port | Proto  | Parameter                          |
|------------|------|--------|------------------------------------|
| nodemanager | 45454 | tcp  | yarn.nodemanager.address           | x
| nodemanager | 8040  | tcp  | yarn.nodemanager.localizer.address |
| nodemanager | 8042  | tcp  | yarn.nodemanager.webapp.address    |
| nodemanager | 8044  | tcp  | yarn.nodemanager.webapp.https.address    |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop YARN NM # IPTables', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      nm_port = yarn.site['yarn.nodemanager.address'].split(':')[1]
      nm_localizer_port = yarn.site['yarn.nodemanager.localizer.address'].split(':')[1]
      nm_webapp_port = yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
      nm_webapp_https_port = yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Container" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_localizer_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Localizer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web Secured UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Package

    module.exports.push name: 'Hadoop YARN NM # Package', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      ctx.service
        name: 'libcgroup'
        if: yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'true'
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-yarn-nodemanager".

    module.exports.push name: 'Hadoop YARN NM # Startup', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-yarn-nodemanager'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/hadoop-yarn-nodemanager'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{yarn.pid_dir}/$SVC_USER/yarn-yarn-nodemanager.pid\""
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

    module.exports.push name: 'Hadoop YARN NM # Directories', timeout: -1, handler: (ctx, next) ->
      {yarn, user, hadoop_group} = ctx.config.ryba
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      log_dirs = yarn.site['yarn.nodemanager.log-dirs'].split ','
      local_dirs = yarn.site['yarn.nodemanager.local-dirs'].split ','
      ctx.mkdir [
        destination: log_dirs
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
      ,
        destination: local_dirs
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
      ], (err, created) ->
        return next err if err
        cmds = []
        for dir in log_dirs then cmds.push cmd: "su -l #{user.name} -c 'ls -l #{dir}'"
        for dir in local_dirs then cmds.push cmd: "su -l #{user.name} -c 'ls -l #{dir}'"
        ctx.execute cmds, (err) ->
          next err, created

## Capacity Planning

Naive discovery of the memory and CPU allocated by this NodeManager.

It is recommended to use the "capacity" script prior install Hadoop on
your cluster. It will suggest you relevant values for your servers with a
global view of your system. In such case, this middleware is bypassed and has
no effect. Also, this isnt included inside the configuration because it need an
SSH connection to the node to gather the memory and CPU informations.

    module.exports.push name: 'Hadoop YARN NM # Capacity Planning', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      return next() if yarn.site['yarn.nodemanager.resource.memory-mb'] and yarn.site['yarn.nodemanager.resource.cpu-vcores']
      # diskNumber = yarn.site['yarn.nodemanager.local-dirs'].length
      memoryAvailableMb = Math.round ctx.meminfo.MemTotal / 1024 / 1024 * .8
      yarn.site['yarn.nodemanager.resource.memory-mb'] ?= memoryAvailableMb
      yarn.site['yarn.nodemanager.resource.cpu-vcores'] ?= ctx.cpuinfo.length

## Configuration

    module.exports.push name: 'Hadoop YARN NM # Configuration', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        backup: true
      , next

## Container Executor

    module.exports.push name: 'Hadoop YARN NM # Container Executor', handler: (ctx, next) ->
      {container_executor, hadoop_conf_dir} = ctx.config.ryba
      ce_group = container_executor['yarn.nodemanager.linux-container-executor.group']
      modified = false
      do_stat = ->
        ce = '/usr/lib/hadoop-yarn/bin/container-executor';
        ctx.chown
          destination: ce
          uid: 'root'
          gid: ce_group
        , (err, chowned) ->
          return next err if err
          modified = true if chowned
          ctx.chmod
            destination: ce
            mode: 0o6050
          , (err, chmoded) ->
            return next err if err
            modified = true if chmoded
            do_conf()
      do_conf = ->
        ctx.ini
          destination: "#{hadoop_conf_dir}/container-executor.cfg"
          content: container_executor
          uid: 'root'
          gid: ce_group
          mode: 0o0640
          separator: '='
          backup: true
        , (err, inied) ->
          modified = true if inied
          next err, modified
      do_stat()

    module.exports.push name: 'Hadoop YARN NM # Kerberos', handler: (ctx, next) ->
      {yarn, hadoop_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: yarn.site['yarn.nodemanager.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: yarn.site['yarn.nodemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

    module.exports.push name: 'Hadoop YARN NM # CGroup', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      return next() unless yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'true'
      ctx.mkdir
        destination: "#{yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path']}/cpu"
        mode: 0o1777
      , next

### HDFS Layout

Create the YARN log directory defined by the property 
"yarn.nodemanager.remote-app-log-dir". The default value in the HDP companion
files is "/app-logs". The command `hdfs dfs -ls /` should print:

```
drwxrwxrwt   - yarn   hadoop            0 2014-05-26 11:01 /app-logs
```

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'Hadoop YARN NM # HDFS layout', handler: (ctx, next) ->
      {yarn, hadoop_group} = ctx.config.ryba
      remote_app_log_dir = yarn.site['yarn.nodemanager.remote-app-log-dir']
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d #{remote_app_log_dir}; then exit 2; fi
        hdfs dfs -mkdir -p #{remote_app_log_dir}
        hdfs dfs -chown #{yarn.user.name}:#{hadoop_group.name} #{remote_app_log_dir}
        hdfs dfs -chmod 1777 #{remote_app_log_dir}
        """
        code_skipped: 2
      , next

    module.exports.push 'ryba/hadoop/yarn_nm_start'

## Module Dependencies

    mkcmd = require '../lib/mkcmd'


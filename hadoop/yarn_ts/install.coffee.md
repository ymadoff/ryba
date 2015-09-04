
# YARN Timeline Server Install

The Timeline Server is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    # module.exports.push require('./index').configure

## IPTables

| Service   | Port       | Proto     | Parameter                                  |
|-----------|------------|-----------|--------------------------------------------|
| timeline  | 10200      | tcp/http  | yarn.timeline-service.address              |
| timeline  | 8188 | tcp/http  | yarn.timeline-service.webapp.address       |
| timeline  | 8190      | tcp/https | yarn.timeline-service.webapp.https.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'YARN TS # IPTables', handler: ->
      {yarn} = @config.ryba
      [_, rpc_port] = yarn.site['yarn.timeline-service.address'].split ':'
      [_, http_port] = yarn.site['yarn.timeline-service.webapp.address'].split ':'
      [_, https_port] = yarn.site['yarn.timeline-service.webapp.https.address'].split ':'
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver RPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTPS" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-yarn-timelineserver" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

    module.exports.push name: 'YARN TS # Service', handler: ->
      @service
        name: 'hadoop-yarn-timelineserver'
      @hdp_select
        name: 'hadoop-yarn-client' # Not checked
        name: 'hadoop-yarn-timelineserver'
      @write
        source: "#{__dirname}/../resources/hadoop-yarn-timelineserver"
        local_source: true
        destination: '/etc/init.d/hadoop-yarn-timelineserver'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hadoop-yarn-timelineserver restart"
        if: -> @status -3

## Configuration

Update the "yarn-site.xml" configuration file.

    module.exports.push name: 'YARN TS # Configuration', handler: ->
      return next() unless @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      {hadoop_conf_dir, yarn, hadoop_group} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn.site
        merge: true
        backup: true

# Layout

    module.exports.push name: 'YARN TS # Layout', timeout: -1, handler: ->
      {yarn, hadoop_group} = @config.ryba
      @mkdir
        destination: yarn.site['yarn.timeline-service.leveldb-timeline-store.path']
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0750
        parent: true

# HDFS Layout

See:

*   [YarnConfiguration](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#L1425-L1426)
*   [FileSystemApplicationHistoryStore](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-applicationhistoryservice/src/main/java/org/apache/hadoop/yarn/server/applicationhistoryservice/FileSystemApplicationHistoryStore.java)

Note, this is not documented anywhere and might not be considered as a best practice.

    module.exports.push name: 'YARN TS # HDFS layout', timeout: -1, handler: ->
      {yarn} = @config.ryba
      return next() unless yarn.site['yarn.timeline-service.generic-application-history.store-class'] is "org.apache.hadoop.yarn.server.applicationhistoryservice.FileSystemApplicationHistoryStore"
      dir = yarn.site['yarn.timeline-service.fs-history-store.uri']
      @wait_execute
        cmd: mkcmd.hdfs @, "hdfs dfs -test -d #{path.dirname dir}"
      @execute
        cmd: mkcmd.hdfs @, """
        hdfs dfs -mkdir -p #{dir}
        hdfs dfs -chown #{yarn.user.name} #{dir}
        hdfs dfs -chmod 1777 #{dir}
        """
        not_if_exec: "[[ hdfs dfs -d #{dir} ]]"

yarn.site['yarn.timeline-service.fs-history-store.uri']

## Kerberos

Create the Kerberos service principal by default in the form of
"ats/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/ats.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    module.exports.push 'ryba/hadoop/hdfs_client/install'
    module.exports.push name: 'YARN TS # Kerberos', timeout: -1, handler: ->
      {yarn, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: yarn.site['yarn.timeline-service.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.timeline-service.keytab']
        uid: yarn.user.name
        gid: yarn.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'

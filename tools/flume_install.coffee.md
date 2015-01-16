
# Flume

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs' # Users and groups created by "zookeeper" and "hadoop-hdfs" dependencies
    module.exports.push require('./flume').configure

## Users & Groups

By default, the "flume" package create the following entries:

```bash
cat /etc/passwd | grep flume
flume:x:495:496:Flume:/var/lib/flume:/sbin/nologin
cat /etc/group | grep flume
flume:x:496:
```

Note, the "flume" package rely on the "zookeeper" and "hadoop-hdfs" dependencies
creating the "zookeeper" and "hdfs" users and the "hadoop" and "hdfs" group.

    module.exports.push name: 'Flume # Users & Groups', handler: (ctx, next) ->
      {flume_group, flume_user} = ctx.config.ryba
      ctx.group flume_group, (err, gmodified) ->
        return next err if err
        ctx.user flume_user, (err, umodified) ->
          next err, gmodified or umodified

## Install

The package "flume" is installed.

    module.exports.push name: 'Flume # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service name: 'flume', next

## Kerberos

The flume principal isn't used yet and is created to be at our disposal for
later usage. It is placed inside the flume configuration directory, by default
"/etc/flume/conf/flume.service.keytab" with restrictive permissions set to
"0600".

    module.exports.push name: 'Flume # Kerberos', handler: (ctx, next) ->
      {flume_user, flume_group, flume_conf_dir, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "#{flume_user.name}/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "#{flume_conf_dir}/flume.service.keytab"
        uid: flume_user.name
        gid: flume_group.name
        mode: 0o600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Check

We didnt yet activated any check. There could be two types, one using a kerberos
user and one using interpolation.

    # module.exports.push name: 'Flume # Check', timeout: -1, handler: (ctx, next) ->
    #   ctx.write
    #     content: """
    #     # Name the components on this agent
    #     a1.sources = r1
    #     a1.sinks = k1, k2
    #     a1.channels = c1
    #     # Describe/configure the source
    #     a1.sources.r1.type = netcat
    #     a1.sources.r1.bind = localhost
    #     a1.sources.r1.port = 44444
    #     a1.sinks.k1.type = HDFS
    #     a1.sinks.k1.hdfs.kerberosPrincipal = flume/_HOST@YOUR-REALM.COM
    #     a1.sinks.k1.hdfs.kerberosKeytab = /etc/flume/conf/flume.keytab
    #     a1.sinks.k1.hdfs.proxyUser = test
    #     a1.sinks.k2.type = HDFS
    #     a1.sinks.k2.hdfs.kerberosPrincipal = flume/_HOST@YOUR-REALM.COM
    #     a1.sinks.k2.hdfs.kerberosKeytab = /etc/flume/conf/flume.keytab
    #     a1.sinks.k2.hdfs.proxyUser = hdfs
    #     """
    #     destination: '/tmp/flume.conf'
    #   , (err, written) ->
    #     return next err if written
    #     next null, ctx.OK
    #     # ctx.execute
    #     #   cmd: "flume-ng agent --conf conf --conf-file example.conf --name a1 -Dflume.root.logger=INFO,console"


## Flume inside a Kerberos environment


*   Flume agent machine that writes to HDFS (via a configured HDFS sink) 
    needs a Kerberos principal of the form: 
    flume/fully.qualified.domain.name@YOUR-REALM.COM
*   Each Flume agent machine that writes to HDFS does not need to 
    have a flume Unix user account to write files owned by the flume 
    Hadoop/Kerberos user. Only the keytab for the flume Hadoop/Kerberos 
    user is required on the Flume agent machine.   
*   DataNode machines do not need Flume Kerberos keytabs and also do 
    not need the flume Unix user account.   
*   TaskTracker (MRv1) or NodeManager (YARN) machines need a flume Unix 
    user account if and only if MapReduce jobs are being run as the 
    flume Hadoop/Kerberos user.   
*   The NameNode machine needs to be able to resolve the groups of the 
    flume user. The groups of the flume user on the NameNode machine 
    are mapped to the Hadoop groups used for authorizing access.   
*   The NameNode machine does not need a Flume Kerberos keytab.   

## Resources

*   [Flume Account Requirements](https://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_4_3.html)
*   [Secure Impersonation]](https://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_4_2.html)














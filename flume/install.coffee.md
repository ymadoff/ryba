
# Flume

    module.exports = header: 'Flume Install', handler: ->
      {flume, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

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

      @group @config.ryba.flume.group
      @system.user @config.ryba.flume.user

## Install

The package "flume" is installed.

      @service
        name: 'flume'
      @hdp_select
        name: 'flume-server'

## Kerberos

The flume principal isn't used yet and is created to be at our disposal for
later usage. It is placed inside the flume configuration directory, by default
"/etc/flume/conf/flume.service.keytab" with restrictive permissions set to
"0600".

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: "#{flume.user.name}/#{@config.host}@#{realm}"
        randkey: true
        keytab: "#{flume.conf_dir}/flume.service.keytab"
        uid: flume.user.name
        gid: flume.group.name

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

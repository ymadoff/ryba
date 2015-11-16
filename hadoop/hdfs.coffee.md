
# Hadoop HDFS

This module is not intended to be used directly. It is required by other modules to
setup a base installation. Such modules include "ryba/hadoop/hdfs_client",
"ryba/hadoop/hdfs_dn" and "ryba/hadoop/hdfs_nn".

In its current state, we are only supporting the installation of a
[secure cluster with Kerberos][secure].

[secure]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SecureMode.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/core'

## Configure

The properties "hdp.hdfs.site['dfs.namenode.name.dir']" and
"hdp.hdfs.site['dfs.datanode.data.dir']" are required.

*   `ryba.hdfs.hadoop_policy`
*   `ryba.hdfs.hdfs.site` (object)
    Properties added to the "hdfs-site.xml" file.
*   `ryba.hdfs.nameservice`
    The Unix MapReduce group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "hdfs": {
      site": {
        "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      throw new Error "Missing value for 'hdfs.krb5_user.password'" unless ctx.config.ryba.hdfs.krb5_user.password?
      throw new Error "Missing value for 'krb5_user.password'" unless ctx.config.ryba.krb5_user.password?

## Kerberos User

Create the HDFS user principal. This will be the super administrator for the HDFS
filesystem. Note, we do not create a principal with a keytab to allow HDFS login
from multiple sessions with braking an active session.

    module.exports.push header: 'HDFS # Kerberos User', handler: ->
      {hdfs, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc merge
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , hdfs.krb5_user

## Dependencies

    {merge} = require 'mecano/lib/misc'

[hdfs_secure]: http://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-common/SecureMode.html#DataNode
[hawq]: http://docs.gopivotal.com/pivotalhd/InstallingHAWQ.html
[greenplum]: http://nixustechnologies.com/2014/03/31/install-greenplum-community-edition/
[mapr]: http://doc.mapr.com/display/MapR/Preparing+Each+Node
[hpl]: http://www.slideshare.net/technmsg/improving-hadoop-performancevialinux
[kate]: http://fr.slideshare.net/cloudera/hadoop-troubleshooting-101-kate-ting-cloudera

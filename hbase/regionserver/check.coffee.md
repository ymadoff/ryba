
# HBase RegionServer Check

    module.exports = header: 'HBase RegionServer Check', label_true: 'CHECKED', handler: ->
      [hbase_master] = @contexts 'ryba/hbase/master'
      {core_site, hbase} = @config.ryba
      rootdir = hbase_master.config.ryba.hbase.master.site['hbase.rootdir']
      protocol = if hbase.rs.site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = hbase.rs.site['hbase.regionserver.info.port']
      url = "#{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=HBase,name=RegionServer,sub=Server"

## Wait

      @call 'ryba/hbase/regionserver/wait'

## Check FSCK

It is possible that HBase fail to started because of currupted WAL files.
Corrupted blocks for removal can be found with the command: 
`hdfs fsck / | egrep -v '^\.+$' | grep -v replica | grep -v Replica`
Additionnal information may be found on the [CentOS HowTos site][corblk].

[corblk]: http://centoshowtos.org/hadoop/fix-corrupt-blocks-on-hdfs/

      @execute
        header: 'FSCK'
        label_true: 'CHECKED'
        cmd: mkcmd.hdfs @, "hdfs fsck #{rootdir}/WALs | grep 'Status: HEALTHY'"
        relax: true
      , (err) ->
        @log? 'WARN, fsck show WAL corruption' if err

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The RegionServer webapp located in "/usr/lib/hbase/hbase-webapps/regionserver" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

      @execute
        header: 'SPNEGO'
        label_true: 'CHECKED'
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"

## Check HTTP JMX

      @execute
        header: 'HTTP JMX'
        label_true: 'CHECKED'
        cmd: mkcmd.test @, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        if [ "$host" != '#{@config.host}' ] ; then exit 1; fi
        """


## Dependencies

    mkcmd = require '../../lib/mkcmd'

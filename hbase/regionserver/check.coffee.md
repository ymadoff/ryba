
# HBase RegionServer Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Check FSCK

It is possible that HBase fail to started because of currupted WAL files.
Corrupted blocks for removal can be found with the command: 
`hdfs fsck / | egrep -v '^\.+$' | grep -v replica | grep -v Replica`
Additionnal information may be found on the [CentOS HowTos site][corblk].

[corblk]: http://centoshowtos.org/hadoop/fix-corrupt-blocks-on-hdfs/

    module.exports.push header: 'HBase RegionServer # Check FSCK', label_true: 'CHECKED', handler: ->
      rootdir = @contexts('ryba/hbase/master')[0].config.ryba.hbase.site['hbase.rootdir']
      @execute
        cmd: mkcmd.hdfs @, "hdfs fsck #{rootdir}/WALs | grep 'Status: HEALTHY'"
        relax: true
      , (err) ->
        @log? 'WARN, fsck show WAL corruption' if err

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The RegionServer webapp located in "/usr/lib/hbase/hbase-webapps/regionserver" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push header: 'HBase RegionServer # Check SPNEGO', label_true: 'CHECKED', handler: ->
      {core_site, hbase} = @config.ryba
      @execute
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"

## Check HTTP JMX

    module.exports.push header: 'HBase RegionServer # Check HTTP JMX', retry: 200, label_true: 'CHECKED', handler: ->
      {hbase} = @config.ryba
      protocol = if hbase.site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = hbase.site['hbase.regionserver.info.port']
      url = "#{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=HBase,name=RegionServer,sub=Server"
      @execute
        cmd: mkcmd.test @, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        if [ "$host" != '#{@config.host}' ] ; then exit 1; fi
        """

## Shell

Create a "ryba" namespace and set full permission to the "ryba" user. This
namespace is used by other modules as a testing environment.

Namespace and permissions are implemented and illustrated in [HBASE-8409].

TODO: move to install

    module.exports.push header: 'HBase RegionServer # Check Shell', timeout:-1, label_true: 'CHECKED', handler: ->
      {hbase} = @config.ryba
      keytab = hbase.site['hbase.regionserver.keytab.file']
      principal = hbase.site['hbase.regionserver.kerberos.principal'].replace '_HOST', @config.host
      @execute
        cmd: mkcmd.hbase @, """
        if hbase shell 2>/dev/null <<< "user_permission 'ryba'" | egrep '[1-9][0-9]* row'; then exit 2; fi
        hbase shell 2>/dev/null <<-CMD
          create 'ryba', 'family1'
          grant 'ryba', 'RWC', 'ryba'
        CMD
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        hasCreatedTable = /create 'ryba', 'family1'\n0 row/.test stdout
        hasGrantedAccess = /grant 'ryba', 'RWC', 'ryba'\n0 row/.test stdout
        throw Error 'Invalid command output' if executed and (not hasCreatedTable or not hasGrantedAccess)
      # Note: apply this when namespace are functional
      # @execute
      #   cmd: mkcmd.hbase @, """
      #   if hbase shell 2>/dev/null <<< "list_namespace_tables 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
      #   hbase shell 2>/dev/null <<-CMD
      #     create_namespace 'ryba'
      #     grant 'ryba', 'RWC', '@ryba'
      #   CMD
      #   """
      #   code_skipped: 2
      # , (err, executed, stdout) ->
      #   hasCreatedNamespace = /create_namespace 'ryba'\n0 row/.test stdout
      #   hasGrantedAccess = /grant 'ryba', 'RWC', '@ryba'\n0 row/.test stdout
      #   return  Error 'Invalid command output' if executed and ( not hasCreatedNamespace or not hasGrantedAccess)
      #    err, executed

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[HBASE-8409]: https://issues.apache.org/jira/browse/HBASE-8409

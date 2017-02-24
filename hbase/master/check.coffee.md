
# HBase Master Check

    module.exports = header: 'HBase Master Check', label_true: 'CHECKED', handler: ->
      {core_site, hbase} = @config.ryba
      protocol = if hbase.master.site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = hbase.master.site['hbase.master.info.port']
      url = "#{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=HBase,name=Master,sub=Server"

## Wait

Wait for the service to be started.

      @call once: true, 'ryba/hbase/master/wait'

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Master webapp located in "/usr/lib/hbase/hbase-webapps/master" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"

## Check HTTP JMX

      @system.execute
        header: 'HTTP JMX'
        cmd: mkcmd.test @, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        if [ "$host" != '#{@config.host}' ] ; then exit 1; fi
        """

## Dependencies

    mkcmd = require '../../lib/mkcmd'

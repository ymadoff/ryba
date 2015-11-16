
# HBASE Master Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Master webapp located in "/usr/lib/hbase/hbase-webapps/master" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push header: 'HBase Master # Check SPNEGO', label_true: 'CHECKED', handler: ->
      {core_site, hbase} = @config.ryba
      @execute
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"

## Check HTTP JMX

    module.exports.push header: 'HBase Master # Check HTTP JMX', retry: 200, label_true: 'CHECKED', handler: ->
      {hbase} = @config.ryba
      protocol = if hbase.site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = hbase.site['hbase.master.info.port']
      url = "#{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=HBase,name=Master,sub=Server"
      @execute
        cmd: mkcmd.test @, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        if [ "$host" != '#{@config.host}' ] ; then exit 1; fi
        """

## Dependencies

    mkcmd = require '../../lib/mkcmd'

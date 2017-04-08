
# Knox Check

Validating Service Connectivity, based on [Hortonworks Documentation][doc]

    module.exports = header: 'Knox Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {knox} = @config.ryba
      return unless knox.test_user?.name? and knox.test_user?.password?

## Check WebHDFS Proxy

Testing WebHDFS by getting the home directory

At the gateway host, enter `curl --negotiate -ku : http://$webhdfs-host:50470/webhdfs/v1?op=GETHOMEDIRECTORY`. 
The host displays: {"Path":"/user/gopher"}
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/webhdfs/v1?op=GETHOMEDIRECTORY`.
The external client displays: {"Path":"/user/gopher"}

curl -fiku hdfs:hdfs123 "https://front1.ryba:8443/gateway/torval/webhdfs/v1/?op=GETHOMEDIRECTORY"

      @call header: 'WebHDFS', ->
        topologies = Object.keys(knox.topologies).filter((tp) -> knox.topologies[tp].services.webhdfs?)
        for tp in topologies
          @system.execute
            cmd: "curl -fiku #{knox.test_user.name}:#{knox.test_user.password} https://#{@config.host}:#{knox.site['gateway.port']}/#{knox.site['gateway.path']}/#{tp}/webhdfs/v1/?op=GETHOMEDIRECTORY"

## Check WebHCat Proxy

Testing WebHCat/Templeton by getting the version

At the gateway host, enter `curl --negotiate -u : http://$webhcat-host:50111/templeton/v1/version`.
The host displays: {"supportedVersions":["v1"],"version":"v1"}
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/webhcat/v1/version`.
The external client displays: {"supportedVersions":["v1"],"version":"v1"}

      @call header: 'WebHCat', ->
        topologies = Object.keys(knox.topologies).filter((tp) -> knox.topologies[tp].services.webhcat)
        for tp in topologies
          @system.execute
            cmd: "curl -fiku #{knox.test_user.name}:#{knox.test_user.password} https://#{@config.host}:#{knox.site['gateway.port']}/#{knox.site['gateway.path']}/#{tp}/webhcat/v1/version"

## Check HBase REST Proxy

Testing HBase/Stargate by getting the version

At the gateway host, enter `curl --negotiate -u : http://$hbase-host:60080/version`.
The host displays:
rest 0.0.2 JVM: Oracle Corporation 1.7.0_51-24.45-b08 OS: Linux 3.8.0-29-generic amd64 Server: jetty/6.1.26 Jersey: 1.8.
At an external client, enter `curl -ku user:password http://$gateway-host:$gateway_port/$gateway/$cluster_name/hbase/version`.
The external client displays:
rest 0.0.2 JVM: Oracle Corporation 1.7.0_51-24.45-b08 OS: Linux 3.8.0-29-generic amd64 Server: jetty/6.1.26 Jersey: 1.8.

      @call header: 'WebHBase', ->
        topologies = Object.keys(knox.topologies).filter((tp) -> knox.topologies[tp].services.webhcat)
        for tp in topologies
          @system.execute
            cmd: "curl -fiku #{knox.test_user.name}:#{knox.test_user.password} https://#{@config.host}:#{knox.site['gateway.port']}/#{knox.site['gateway.path']}/#{tp}/hbase/version"

## Check Oozie Proxy

Testing Oozie by getting the version

At the gateway host, enter `curl --negotiate -u : http://$oozie-host:11000/oozie/v1/admin/build-version`. 
The host displays:
{"buildVersion":"4.0.0.2.1.1.0-302"} 
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/oozie/v1/admin/build-version`.
The external client displays:
{"buildVersion":"4.0.0.2.1.1.0-302"}

      @call header: 'Oozie', ->
        topologies = Object.keys(knox.topologies).filter((tp) -> knox.topologies[tp].services.oozie)
        for tp in topologies
          @system.execute
            cmd: "curl -fiku #{knox.test_user.name}:#{knox.test_user.password} https://#{@config.host}:#{knox.site['gateway.port']}/#{knox.site['gateway.path']}/#{tp}/oozie/v1/admin/build-version"

## Check HiveServer2 Proxy

Testing HiveServer2
Both of the following URLs return an authentication error, which users can safely ignore.

At the gateway host, enter `curl --negotiate -u : http://$hive-host:10001/cliservice`.
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/hive/cliservice`/

      @call header: 'HiveServer2', ->
        topologies = Object.keys(knox.topologies).filter((tp) -> knox.topologies[tp].services.hive)
        for tp in topologies
          @system.execute
            cmd: "curl -fiku #{knox.test_user.name}:#{knox.test_user.password} https://#{@config.host}:#{knox.site['gateway.port']}/#{knox.site['gateway.path']}/#{tp}/hive/cliservice"

[doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.8/bk_Knox_Gateway_Admin_Guide/content/validating_service_connectivity.html

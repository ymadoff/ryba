
# Flume Check

We didnt yet activated any check. There could be two types, one using a kerberos
user and one using interpolation.

## Check

    # module.exports.push header: 'Flume Check', timeout: -1, handler: ->
    #   @file
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
    #     target: '/tmp/flume.conf'
    #   , (err, written) ->
    #     return next err if written
    #     next null, true
    #     # @system.execute
    #     #   cmd: "flume-ng agent --conf conf --conf-file example.conf --name a1 -Dflume.root.logger=INFO,console"

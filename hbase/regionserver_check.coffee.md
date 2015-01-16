
# HBase RegionServer

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./regionserver').configure

## Check HTTP JMX

    module.exports.push name: 'HBase RegionServer # Check HTTP JMX', label_true: 'CHECKED', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      port = hbase.site['hbase.regionserver.info.port']
      url = "http://#{ctx.config.host}:#{port}/jmx?qry=Hadoop:service=HBase,name=RegionServer,sub=Server"
      ctx.execute
        cmd: mkcmd.test ctx, """
        host=`curl -s --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\(.*\)".*$/\1/g'`      
        if [ $host != '#{ctx.config.host}' ] ; then exit 1; fi
        """
      , next

## Shell

Create a "ryba" namespace and set full permission to the "ryba" user. This
namespace is used by other modules as a testing environment.

Namespace and permissions are implemented and illustrated in [HBASE-8409].

    module.exports.push name: 'HBase RegionServer # Check Shell', timeout:-1, label_true: 'CHECKED', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      keytab = hbase.site['hbase.regionserver.keytab.file']
      principal = hbase.site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
      ctx.execute
        cmd: """
        kinit -kt #{keytab} #{principal}
        if hbase shell 2>/dev/null <<< "user_permission 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
        hbase shell 2>/dev/null <<-CMD
          create 'ryba', 'family1'
          grant 'ryba', 'RWC', 'ryba'
        CMD
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        hasCreatedTable = /create 'ryba', 'family1'\n0 row/.test stdout
        hasGrantedAccess = /grant 'ryba', 'RWC', 'ryba'\n0 row/.test stdout
        return next Error 'Invalid command output' if executed and ( not hasCreatedTable or not hasGrantedAccess)
        next err, executed
      # Note: apply this when namespace are functional
      # ctx.execute
      #   cmd: """
      #   kinit -kt #{keytab} #{principal}
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
      #   return next Error 'Invalid command output' if executed and ( not hasCreatedNamespace or not hasGrantedAccess)
      #   next err, if executed then ctx.OK else ctx.PASS

## Module Dependencies

    mkcmd = require '../lib/mkcmd'

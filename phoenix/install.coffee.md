
# Phoenix Install

Please refer to the Hortonworks [documentation][phoenix-doc]

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/java'
    module.exports.push require('../hadoop/core').configure
    module.exports.push require('../hbase').configure
    module.exports.push require('./index').configure
    module.exports.push require '../lib/hdp_select'

## Packages

    module.exports.push name: 'Phoenix # Install', handler: (ctx, next) ->
      ctx.service
        name: 'phoenix'
      .hdp_select
        name: 'phoenix-client'
      .then next

## Env

    module.exports.push name: 'Phoenix # Link to HBase', handler: (ctx, next) ->
      ctx.execute
        cmd:"""
        PKG=`rpm --queryformat "/usr/hdp/current/phoenix-client/lib/phoenix-core-%{VERSION}-%{RELEASE}" -q phoenix`;
        PKG=${PKG/el*/jar};
        ln -sf $PKG /usr/hdp/current/hbase-client/lib/phoenix.jar
        """
        not_if_exists: '/usr/hdp/current/hbase-client/lib/phoenix.jar'
      .then next

    module.exports.push name: 'Phoenix # Hadoop Configuration', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      ctx.execute
        cmd:"""
        ln -sf #{path.join hadoop_conf_dir, 'core-site.xml'} /usr/hdp/current/phoenix-client/bin/core-site.xml
        """
        not_if_exists: '/usr/hdp/current/phoenix-client/bin/core-site.xml'
      .then next

    module.exports.push name: 'Phoenix # HBase Configuration', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd:"""
        ln -sf #{path.join hbase.conf_dir, 'hbase-site.xml'} /usr/hdp/current/phoenix-client/bin/hbase-site.xml
        """
        not_if_exists: '/usr/hdp/current/phoenix-client/bin/hbase-site.xml'
      .then next

    module.exports.push name: 'Phoenix # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      , next

## Initialize

    module.exports.push name: 'Phoenix # Init', timeout: 200000, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      zk_path  = hbase.site['hbase.zookeeper.quorum'].split(',')[0]
      zk_path += ':' + hbase.site['hbase.zookeeper.property.clientPort']
      zk_path += hbase.site['zookeeper.znode.parent']

There is 3 phoenix 'SYSTEM.*' tables. If they don't exist in HBase, we launch
phoenix with hbase admin user.
Independently, if 'ryba' hasn't CREATE right on these 3 tables, it will be granted

      ctx.execute
        cmd: mkcmd.hbase ctx, """
        code=3
        if [ `hbase shell 2>/dev/null <<< "list 'SYSTEM.*'" | egrep '^SYSTEM\.' | wc -l` -lt "3" ]; then
        /usr/hdp/current/phoenix-client/bin/sqlline.py #{zk_path} 2>/dev/null <<< "!q"
        code=0
        fi
        if [ `hbase shell 2>/dev/null <<< "user_permission 'SYSTEM.*'" | egrep 'ryba.*(CREATE|READ|WRITE).*(CREATE|READ|WRITE).*(CREATE|READ|WRITE)' | wc -l` -lt "3" ]; then
        hbase shell 2>/dev/null <<-CMD
        grant 'ryba', 'RWC', 'SYSTEM.CATALOG'
        grant 'ryba', 'RWC', 'SYSTEM.SEQUENCE'
        grant 'ryba', 'RWC', 'SYSTEM.STATS'
        CMD
        code=0
        fi
        exit $code
        """
        code_skipped: 3
      .then next

## Module Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'

[phoenix-doc][http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/HDP_Man_Install_v224/index.html#installing_phoenix]

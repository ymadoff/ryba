
# Druid MiddleManager Install

    module.exports = header: 'Druid MiddleManager Install', handler: ->
      {druid} = @config.ryba
      @call once: true, handler: 'ryba/druid/install'

## IPTables

| Service             | Port | Proto    | Parameter                   |
|---------------------|------|----------|-----------------------------|
| Druid MiddleManager | 8091, 8100–8199 | tcp/http |                  |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.middlemanager.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: '8100–8199', protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-middlemanager"
        source: "#{__dirname}/../resources/druid-middlemanager.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/middleManager/runtime.properties"
        content: druid.middlemanager.runtime
        backup: true
      @file
        target: "#{druid.dir}/conf/druid/middlemanager/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.middlemanager.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.middlemanager.jvm.xmx}"
        ]
      @mkdir
        target: "#{druid.middlemanager.runtime['druid.indexer.task.baseTaskDir']}"
        uid: "#{druid.user.name}"
        gid: "#{druid.group.name}"
        mode: 0o0750

## Hadoop client library

Detect the current Hadoop version and import its client jars. See the 
documentation [Working with different versions of Hadoop](https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md).

      @execute
        cmd: """
        version=`ls #{druid.hadoop_mapreduce_dir}/hadoop-mapreduce-client-core-*.jar | sed 's/.*client-core-\\([0-9]\\.[0-9]\\.[0-9]\\).*/\\1/g'`
        target=/opt/druid-#{druid.version}/hadoop-dependencies/hadoop-client/${version}
        signal=3
        if [ ! -d ${target} ]; then
          mkdir ${target}
        fi
        for file in `ls #{druid.hadoop_mapreduce_dir}/*.jar`; do
          if [ -f $file ] && [ ! -f $target/`basename $file` ]; then
            echo "Import jar to  $target/`basename $file`"
            cp -rp $file $target/`basename $file`
            signal=0
          fi
        done
        exit $signal
        """
        code_skipped: 3

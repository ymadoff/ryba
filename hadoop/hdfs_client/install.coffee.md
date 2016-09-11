
# Hadoop HDFS Client Install

    module.exports = header: 'HDFS Client Install', handler: ->
      {hadoop_conf_dir, core_site, hdfs, hadoop_group} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## Packages

Install the "hadoop-client" and "openssl" packages as well as their
dependecies.

The environment script "hadoop-env.sh" from the HDP companion files is also
uploaded when the package is first installed or upgraded. Be careful, the
original file will be overwritten with and user modifications. A copy will be
made available in the same directory after any modification.

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'openssl'
        @service
          name: 'hadoop-client'
        @hdp_select
          name: 'hadoop-client'

## Env

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

      @render
        header: 'Env'
        target: "#{hadoop_conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local_source: true
        context: @config
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true

## Configuration

Update the "core-site.xml" configuration file with properties from the
"ryba.core_site" configuration.

      @hconfigure
        header: 'Core Configuration'
        target: "#{hadoop_conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_source: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Configuration'
        target: "#{hadoop_conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_source: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        backup: true

      @call header: 'Jars', handler: ->
        {core_jars} = @config.ryba
        core_jars = Object.keys(core_jars).map (k) -> core_jars[k]
        remote_files = null
        @call (_, callback) ->
          @fs.readdir '/usr/hdp/current/hadoop-hdfs-client/lib', (err, files) ->
            remote_files = files unless err
            callback err
        @call ->
          remove_files = []
          core_jars = for jar in core_jars
            filtered_files = multimatch remote_files, jar.match
            remove_files.push (filtered_files.filter (file) -> file isnt jar.filename)...
            continue if jar.filename in remote_files
            jar
          @remove ( # Remove jar if already uploaded
            target: path.join '/usr/hdp/current/hadoop-hdfs-client/lib', file
          ) for file in remove_files
          @download (
            source: jar.source
            target: path.join '/usr/hdp/current/hadoop-hdfs-client/lib', "#{jar.filename}"
          ) for jar in core_jars
          @download (
            source: jar.source
            target: path.join '/usr/hdp/current/hadoop-yarn-client/lib', "#{jar.filename}"
          ) for jar in core_jars

## SSL

      @call header: 'SSL', retry: 0, handler: ->
        {hadoop_conf_dir, ssl, ssl_server, ssl_client} = @config.ryba
        ssl_client['ssl.client.truststore.location'] = "#{hadoop_conf_dir}/truststore"
        @hconfigure
          target: "#{hadoop_conf_dir}/ssl-client.xml"
          properties: ssl_client
        @java_keystore_add
          keystore: ssl_client['ssl.client.truststore.location']
          storepass: ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true


# Hadoop KMS Install

    module.exports = header: 'Hadoop KMS Install', handler: ->
      {kms, hadoop_group} = @config.ryba
      {ssl} = @config.ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Users & Groups

      @group kms.group
      @system.user kms.user

## Packages

      @call header: 'Packages', timeout: -1, handler: (options) ->
        @service
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'
        @execute
          cmd: """
          version=`ls -l /usr/hdp/current/hadoop-mapreduce-client | sed 's/.*-> \\/usr\\/hdp\\/\\(.*\\)\\/.*/\\1/g'`
          if [ -z "$version" ]; then echo 'Version not found' && exit 1; fi
          echo version is $version
          if [ -d /usr/hdp/$version/hadoop-kms ]; then exit 3; fi
          mkdir -p /usr/hdp/$version/hadoop-kms
          tar xzf /usr/hdp/$version/hadoop/mapreduce.tar.gz --strip-components=1 -C /usr/hdp/$version/hadoop-kms
          chown -R #{kms.user.name}:#{kms.group.name} /usr/hdp/$version/hadoop-kms
          ln -sf /usr/hdp/$version/hadoop-kms /usr/hdp/current/hadoop-kms
          """
          trap: true
          code_skipped: 3
        @service.init
          target: "/etc/init.d/hadoop-kms"
          source: "#{__dirname}/../resources/hadoop-kms.j2"
          local: true
          context: @config
          mode: 0o0755
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: "#{kms.pid_dir}"
          uid: kms.user.name
          gid: kms.group.name
          perm: '0755'
        

## Layout

      @mkdir
        header: 'Layout PID'
        target: "#{kms.pid_dir}"
        uid: kms.user.name
        gid: kms.group.name
        mode: 0o0755
      @mkdir
        header: 'Layout Log'
        target: "#{kms.log_dir}" #/#{kms.user.name}
        uid: kms.user.name
        gid: kms.group.name
        parent: true

## Environment

Maintain the "kms-env.sh" file.

      @render
        header: 'Environment'
        target: "#{kms.conf_dir}/kms-env.sh"
        source: "#{__dirname}/../resources/kms-env.sh.j2"
        local_source: true
        context: @config
        uid: kms.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true

## Configuration

      @hconfigure
        header: 'Configuration'
        target: "#{kms.conf_dir}/kms-site.xml"
        properties: kms.site
        uid: kms.user.name
        gid: kms.user.name
        backup: true
      @hconfigure
        header: 'ACLs'
        target: "#{kms.conf_dir}/kms-acls.xml"
        properties: kms.acls
        uid: kms.user.name
        gid: kms.user.name
        backup: true

## Java KeyStore

      # Server: import certificates, private and public keys to hosts with a server
      @write
        target: "#{kms.site['hadoop.security.keystore.java-keystore-provider.password-file']}"
        content: "lululu"
      @java_keystore_add
        keystore: "#{kms.conf_dir}/kms.keystore"
        storepass: 'lululu'
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: 'jijiji'
        name: @config.shortname
        local_source: true

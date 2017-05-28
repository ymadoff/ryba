
# Ambari Nifi Install

    module.exports = header: 'Ambari Nifi Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

      @service 'nifi'

## Toolkit

      @call header: 'Toolkit', ->
        @file.download
          header: "Download"
          source: options.toolkit.source
          target: path.resolve '/var/tmp', path.basename options.toolkit.source
        @tools.extract
          source: path.resolve '/var/tmp', path.basename options.toolkit.source
          target: options.toolkit.target

## Nifi SSL

      @call header: 'SSL', retry: 0, if: !!options.ssl, ->
        # Client: import certificate to all hosts
        @java.keystore_add
          if_exists: path.dirname options.truststore.target
          keystore: options.truststore.target
          storepass: options.truststore.password
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: options.ssl.cacert.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0644
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          if_exists: path.dirname options.keystore.target
          keystore: options.keystore.target
          storepass: options.keystore.password
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.keystore.keypass
          name: @config.shortname
          local: options.ssl.cert.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0600

## Dependencies

    path = require 'path'

[sr]: http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.2.0/bk_Installing_HDP_AMB/content/_meet_minimum_system_requirements.html

---
title: 
layout: module
---

# Core SSL

Hortonworks mentions 2 strategies to [configure SSL][hdp_ssl], the first one
involves Self-Signed Certificate while the second one use a Certificate
Authority.

For now, only the second approach has been tested and is supported. For this, 
you are responsible for creating your own Private Key and Certificate Authority
(see bellow instructions) and for declaring with the 
"hdp.private\_key\_location" and "hdp.cacert\_location" property.

It is also recommendate to configure the 
"hdp.core\_site['ssl.server.truststore.password']" and 
"hdp.core\_site['ssl.server.keystore.password']" passwords or they will default to
"ryba123".

Here's how to generate your own Private Key and Certificate Authority:

```
openssl genrsa -out hadoop.key 2048
openssl req -x509 -new -key hadoop.key -days 300 -out hadoop.pem -subj "/C=FR/ST=IDF/L=Paris/O=Adaltas/CN=adaltas.com/emailAddress=david@adaltas.com"
```

You can see the content of the root CA certificate with the command:

```
openssl x509 -text -noout -in hadoop.pem
```

You can list the content of the keystore with the command:

```
keytool -list -v -keystore truststore
keytool -list -v -keystore keystore -alias hadoop
```

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push module.exports.configure = (ctx) ->
      require('./core').configure ctx
      require('./yarn').configure ctx
      {core_site, yarn_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.config.ryba.ssl ?= {}
      ssl_client = ctx.config.ryba.ssl_client ?= {}
      ssl_server = ctx.config.ryba.ssl_server ?= {}
      throw new Error 'Required property "hdp.ssl.cacert"' unless ctx.config.ryba.ssl.cacert
      throw new Error 'Required property "hdp.ssl.cert"' unless ctx.config.ryba.ssl.cert
      throw new Error 'Required property "hdp.ssl.key"' unless ctx.config.ryba.ssl.key
      # SSL for HTTPS connection and RPC Encryption
      core_site['hadoop.ssl.require.client.cert'] ?= 'false'
      core_site['hadoop.ssl.hostname.verifier'] ?= 'DEFAULT'
      core_site['hadoop.ssl.keystores.factory.class'] ?= 'org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory'
      core_site['hadoop.ssl.server.conf'] ?= 'ssl-server.xml'
      core_site['hadoop.ssl.client.conf'] ?= 'ssl-client.xml'
      ssl_client['ssl.client.truststore.location'] ?= "#{hadoop_conf_dir}/truststore"
      ssl_client['ssl.client.truststore.password'] ?= 'ryba123'
      ssl_client['ssl.client.truststore.type'] ?= 'jks'
      ssl_server['ssl.server.keystore.location'] ?= "#{hadoop_conf_dir}/keystore"
      ssl_server['ssl.server.keystore.password'] ?= 'ryba123'
      ssl_server['ssl.server.keystore.type'] ?= 'jks'
      ssl_server['ssl.server.truststore.location'] ?= "#{hadoop_conf_dir}/truststore"
      ssl_server['ssl.server.truststore.password'] ?= 'ryba123'
      ssl_server['ssl.server.truststore.type'] ?= 'jks'
      ssl_server['ssl.server.keystore.keypassword'] ?= 'ryba123'

    module.exports.push name: 'HDP Core SSL # Configure', retry: 0, callback: (ctx, next) ->
      {core_site, ssl_server, ssl_client, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure [
        destination: "#{hadoop_conf_dir}/core-site.xml"
        properties: core_site
        merge: true
      ,
        destination: "#{hadoop_conf_dir}/ssl-server.xml"
        properties: ssl_server
        merge: true
      ,
        destination: "#{hadoop_conf_dir}/ssl-client.xml"
        properties: ssl_client
        merge: true
      ], next

    module.exports.push name: 'HDP Core SSL # JKS stores', retry: 0, callback: (ctx, next) ->
      {ssl, ssl_server, ssl_client, hadoop_conf_dir} = ctx.config.ryba
      tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
      modified = false
      do_upload = ->
        ctx.upload [
          source: ssl.cacert
          destination: "#{tmp_location}_cacert"
        ,
          source: ssl.cert
          destination: "#{tmp_location}_cert"
        ,
          source: ssl.key
          destination: "#{tmp_location}_key"
        ], (err, uploaded) ->
          return next err if err
          do_client()
      do_client = ->
        # openssl x509  -noout -in cacert.pem -md5 -fingerprint | sed 's/\(.*\)=\(.*\)/\2/' | sed 's/\://g' | cat
        cmd_cacert_md5 = "openssl x509  -noout -in cacert.pem -md5 -fingerprint | sed 's/\\(.*\\)=\\(.*\\)/\\2/' | sed 's/\\://g' | cat"
        # keytool -list -v -keystore truststore -alias hadoop -storepass ryba123 | grep MD5: | sed 's/\s*MD5\:\s*\(.*\)/\1/'
        cmd_trustore_md5 = "keytool -list -v -keystore keystore -alias hadoop -storepass ryba123 | grep MD5: | sed 's/\\s*MD5\\:\\s*\\(.*\\)/\\1/'"
        ctx.execute
          cmd: """
          user=`openssl x509  -noout -in "#{tmp_location}_cacert" -md5 -fingerprint | sed 's/\\(.*\\)=\\(.*\\)/\\2/' | cat`
          truststore=`keytool -list -v -keystore #{ssl_client['ssl.client.truststore.location']} -alias hadoop_root_ca -storepass #{ssl_client['ssl.client.truststore.password']} | grep MD5: | sed 's/\\s*MD5\\:\\s*\\(.*\\)/\\1/'`
          echo "User CACert: $user"
          echo "Truststore CACert: $truststore"
          if [ "$user" == "$truststore" ]; then exit 3; fi
          # Import root CA certificate into the trustore
          yes | keytool -importcert -alias hadoop_root_ca -file #{tmp_location}_cacert \
            -keystore #{ssl_client['ssl.client.truststore.location']} \
            -storepass #{ssl_client['ssl.client.truststore.password']}
          """
          code_skipped: 3
        , (err, executed) ->
          return next err if err
          modified = true if executed
          return do_server()
      do_server = ->
        return do_cleanup() unless ctx.has_any_modules [
          'ryba/hadoop/hdfs_jn', 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn'
          'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
        ]
        # return do_cleanup() unless ctx.has_module('ryba/hadoop/hdfs_jn') or ctx.has_module('ryba/hadoop/hdfs_nn') or ctx.has_module('ryba/hadoop/hdfs_dn')
        shortname = ctx.config.shortname
        fqdn = ctx.config.host
        ctx.execute [
          # keytool -list -v -keystore keystore -alias hadoop -storepass ryba123 | grep MD5: | sed 's/\s*MD5\:\s*\(.*\)/\1/'
          cmd: """
          user=`openssl x509  -noout -in "#{tmp_location}_cert" -md5 -fingerprint | sed 's/\\(.*\\)=\\(.*\\)/\\2/' | cat`
          keystore=`keytool -list -v -keystore #{ssl_server['ssl.server.keystore.location']} -alias #{shortname} -storepass #{ssl_server['ssl.server.keystore.password']} | grep MD5: | sed 's/\\s*MD5\\:\\s*\\(.*\\)/\\1/'`
          echo "User Certificate: $user"
          echo "Keystore Certificate: $keystore"
          if [ "$user" == "$keystore" ]; then exit 3; fi
          # Create a PKCS12 file that contains key and certificate
          openssl pkcs12 -export \
            -in "#{tmp_location}_cert" -inkey "#{tmp_location}_key" \
            -out "#{tmp_location}_pkcs12" -name #{shortname} \
            -CAfile "#{tmp_location}_cacert" -caname hadoop_root_ca \
            -password pass:#{ssl_server['ssl.server.keystore.keypassword']}
          # Import PKCS12 into keystore
          keytool -importkeystore \
            -deststorepass #{ssl_server['ssl.server.keystore.password']} \
            -destkeypass #{ssl_server['ssl.server.keystore.keypassword']} \
            -destkeystore #{ssl_server['ssl.server.keystore.location']} \
            -srckeystore "#{tmp_location}_pkcs12" -srcstoretype PKCS12 -srcstorepass #{ssl_server['ssl.server.keystore.keypassword']} \
            -alias #{shortname}
          """
          code_skipped: 3
        ,
          cmd: """
          user=`openssl x509  -noout -in "#{tmp_location}_cacert" -md5 -fingerprint | sed 's/\\(.*\\)=\\(.*\\)/\\2/' | cat`
          keystore=`keytool -list -v -keystore #{ssl_server['ssl.server.keystore.location']} -alias hadoop_root_ca -storepass #{ssl_server['ssl.server.keystore.password']} | grep MD5: | sed 's/\\s*MD5\\:\\s*\\(.*\\)/\\1/'`
          echo "User CACert: $user"
          echo "Keystore CACert: $keystore"
          if [ "$user" == "$keystore" ]; then exit 3; fi
          # Import CACert
          yes | keytool -keystore #{ssl_server['ssl.server.keystore.location']} \
            -storepass #{ssl_server['ssl.server.keystore.password']} \
            -alias hadoop_root_ca \
            -import \
            -file #{tmp_location}_cacert
          """
          code_skipped: 3
        ], (err, executed) ->
          return next err if err
          modified = true if executed
          do_cleanup()
      do_cleanup = ->
        ctx.remove [
          destination: "#{tmp_location}_cacert"
        ,
          destination: "#{tmp_location}_cert"
        ,
          destination: "#{tmp_location}_key"
        ,
          destination: "#{tmp_location}_pkcs12"
        ], (err, removed) ->
          return next err if err
          do_end()
      do_end = ->
        next null, modified
      do_upload()


[hdp_ssl]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_reference/content/ch_wire-https.html






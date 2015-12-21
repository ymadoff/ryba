
# Hadoop Core SSL

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
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/lib/hconfigure'

    module.exports.configure = (ctx) ->
      require('./core').configure ctx
      # require('./yarn').configure ctx
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.config.ryba.ssl ?= {}
      ssl_client = ctx.config.ryba.ssl_client ?= {}
      ssl_server = ctx.config.ryba.ssl_server ?= {}
      throw new Error 'Required property "ryba.ssl.cacert"' unless ctx.config.ryba.ssl.cacert
      throw new Error 'Required property "ryba.ssl.cert"' unless ctx.config.ryba.ssl.cert
      throw new Error 'Required property "ryba.ssl.key"' unless ctx.config.ryba.ssl.key
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
      ssl_server['ssl.server.keystore.keypassword'] ?= 'ryba123'
      ssl_server['ssl.server.truststore.location'] ?= "#{hadoop_conf_dir}/truststore"
      ssl_server['ssl.server.truststore.password'] ?= 'ryba123'
      ssl_server['ssl.server.truststore.type'] ?= 'jks'

## SSL

    module.exports.push header: 'Hadoop Core # SSL', retry: 0, handler: ->
      {ssl, ssl_server, ssl_client, hadoop_conf_dir} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/ssl-server.xml"
        properties: ssl_server
      @hconfigure
        destination: "#{hadoop_conf_dir}/ssl-client.xml"
        properties: ssl_client
      # Client: import certificate to all hosts
      @java_keystore_add
        keystore: ssl_client['ssl.client.truststore.location']
        storepass: ssl_client['ssl.client.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # Server: import certificates, private and public keys to hosts with a server
      @java_keystore_add
        keystore: ssl_server['ssl.server.keystore.location']
        storepass: ssl_server['ssl.server.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: ssl_server['ssl.server.keystore.keypassword']
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: ssl_server['ssl.server.keystore.location']
        storepass: ssl_server['ssl.server.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true

## Dependencies

    path = require 'path'

[hdp_ssl]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_reference/content/ch_wire-https.html

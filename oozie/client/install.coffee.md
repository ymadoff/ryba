
# Oozie Client Install

Install and configure an Oozie client environment.

The `oozie` command doesnt reference any configuration. It expect the
environmental variable "OOZIE_URL" to connect to the server.

Additionnal oozie properties may be defined inside the "OOZIE_CLIENT_OPTS"
environmental variables. For example, HDP declare its version as
"-Dhdp.version=${HDP_VERSION}".

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## Install

Install the oozie client package. This package doesn't create any user and group.

    module.exports.push name: 'Oozie Client # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'oozie-client'
      .hdp_select
        name: 'oozie-client'
      .then next

## Profile

Expose the "OOZIE_URL" environmental variable to every users.

    module.exports.push name: 'Oozie Client # Profile', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.write
        destination: '/etc/profile.d/oozie.sh'
        # export OOZIE_CLIENT_OPTS='-Djavax.net.ssl.trustStore=/etc/hadoop/conf/truststore'
        content: """
        #!/bin/bash
        export OOZIE_URL=#{oozie.site['oozie.base.url']}
        """
        mode: 0o0755
      , next

## SSL

Over HTTPS, the certificate must be imported into the JRE's keystore for the
client to submit jobs. Setting the java property "javax.net.ssl.trustStore"
in the "OOZIE_CLIENT_OPTS" environmental variable (both in shell and
"oozie-env.sh" file) is enough to retrieve the oozie status but is not honored
when submiting an Oozie job (erreur inside the mapreduce action).

At the moment, we only support adding the certificate authority into the default
Java location ("$JRE_HOME/lib/security/cacerts").

```
keytool -keystore ${JAVA_HOME}/jre/lib/security/cacerts -delete -noprompt -alias tomcat
keytool -keystore ${JAVA_HOME}/jre/lib/security/cacerts -import -alias tomcat -file master3_cert.pem
```

    module.exports.push name: 'Oozie Client # SSL', handler: (ctx, next) ->
      {java_home, jre_home} = ctx.config.java
      {ssl, oozie} = ctx.config.ryba
      tmp_location = "/tmp/ryba_oozie_client_#{Date.now()}"
      ctx
      .upload
        source: ssl.cacert
        destination: "#{tmp_location}_cacert"
      .java_keystore_add
        keystore: "#{jre_home or java_home}/lib/security/cacerts"
        storepass: "changeit"
        caname: "tomcat"
        cacert: "#{tmp_location}_cacert"
      .remove
        destination: "#{tmp_location}_cacert"
      .then next

    module.exports.push 'ryba/oozie/client/check'

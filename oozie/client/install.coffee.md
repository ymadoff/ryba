
# Oozie Client Install

Install and configure an Oozie client environment.

The `oozie` command doesnt reference any configuration. It expect the
environmental variable "OOZIE_URL" to connect to the server.

Additionnal oozie properties may be defined inside the "OOZIE_CLIENT_OPTS"
environmental variables. For example, HDP declare its version as
"-Dhdp.version=${HDP_VERSION}".
  
    module.exports = header: 'Oozie Client Install', timeout: -1, handler: ->
      {oozie, hadoop_conf_dir, yarn, ssl} = @config.ryba
      {java_home, jre_home} = @config.java

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## Install

Install the oozie client package. This package doesn't create any user and group.

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'oozie-client'
        @hdp_select
          name: 'oozie-client'

## Profile

Expose the "OOZIE_URL" environmental variable to every users.

      @write
        header: 'Profile Env'
        destination: '/etc/profile.d/oozie.sh'
        # export OOZIE_CLIENT_OPTS='-Djavax.net.ssl.trustStore=/etc/hadoop/conf/truststore'
        content: """
        #!/bin/bash
        export OOZIE_URL=#{oozie.site['oozie.base.url']}
        """
        mode: 0o0755

## Configuration

      @hconfigure
        header: 'Oozie site'
        destination: "#{oozie.conf_dir}/oozie-site.xml"
        default: "#{__dirname}/../resources/oozie-site.xml"
        local_default: true
        properties: oozie.site
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
        merge: true
        backup: true

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

      @call header: 'Client SSL', handler: ->
        tmp_location = "/tmp/ryba_oozie_client_#{Date.now()}"
        @download
          source: ssl.cacert
          destination: "#{tmp_location}_cacert"
          shy: true
        @java_keystore_add
          keystore: "#{jre_home or java_home}/lib/security/cacerts"
          storepass: "changeit"
          caname: "ryba_cluster" # was tomcat
          cacert: "#{tmp_location}_cacert"
        @remove
          destination: "#{tmp_location}_cacert"
          shy: true

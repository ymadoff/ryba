
# Hue Install

Here's how to uninstall Hue: `rpm -qa | grep hue | xargs sudo rpm -e`. This
article from december 2014 describe how to 
[install the latest version of hue on HDP](http://gethue.com/how-to-deploy-hue-on-hdp/).

    module.exports = header: 'Hue Install', handler: ->
      {realm, hue} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Users & Groups

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

      @group header: 'Group', hue.group
      @user header: 'User', hue.user

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hue.ini.desktop.http_port, protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Packages

The packages "extjs-2.2-1" and "hue" are installed.

      @service header: 'Packages', name: 'hue'

## WebHCat


Update the "webhcat-site.xml" on the server running the "webhcat" service 
to allow impersonnation through the "hue" user.

TODO: only work if WebHCat is running on the same server as Hue

      {webhcat} = @config.ryba
      webhcat_server = @host_with_module 'ryba/hive/webhcat'
      throw Error "WebHCat shall be on the same server as Hue" unless webhcat_server is @config.host
      @hconfigure
        header: 'WebHCat'
        target: "#{webhcat.conf_dir}/webhcat-site.xml"
        properties: 
          'webhcat.proxyuser.hue.hosts': '*'
          'webhcat.proxyuser.hue.groups': '*'
        merge: true

## Oozie


Update the "oozie-site.xml" on the server running the "oozie" service 
to allow impersonnation through the "hue" user.

TODO: only work if Oozie is running on the same server as Hue

      {oozie} = @config.ryba
      oozie_server = @host_with_module 'ryba/oozie/server'
      return Error "Oozie shall be on the same server as Hue" unless oozie_server is @config.host
      @hconfigure
        header: 'Oozie'
        target: "#{oozie.conf_dir}/oozie-site.xml"
        properties: 
          'oozie.service.ProxyUserService.proxyuser.hue.hosts': '*'
          'oozie.service.ProxyUserService.proxyuser.hue.groups': '*'
        merge: true

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html) 
recommandations. Merge the configuration object from "hdp.hue.ini" with the properties of the target file. 

      @file.ini
        header: 'Configure'
        target: "#{hue.conf_dir}/hue.ini"
        content: hue.ini
        merge: true
        parse: misc.ini.parse_multi_brackets 
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
        uid: hue.user.name
        gid: hue.group.name
        mode: 0o0750

## Database

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is 
the default database while mysql is the recommanded choice.

      @call header: 'Database', handler: ->
        {hue, db_admin} = @config.ryba
        switch hue.ini.desktop.database.engine
          when 'mysql'
            {host, port, user, password, name} = hue.ini.desktop.database
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
            @execute
              cmd: """
              #{mysql_exec} "
              create database #{name};
              grant all privileges on #{name}.* to '#{user}'@'localhost' identified by '#{password}';
              grant all privileges on #{name}.* to '#{user}'@'%' identified by '#{password}';
              flush privileges;
              "
              """
              unless_exec: "#{mysql_exec} 'use #{name}'"
            @execute
              # TODO: handle updates
              cmd: """
              su -l #{hue.user.name} -c "/usr/lib/hue/build/env/bin/hue syncdb --noinput"
              """
              unless_exec: "#{mysql_exec} 'show tables from #{name};' | grep auth"
          else throw Error 'Hue database engine not supported'

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/hue.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: hue.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: "/etc/hue/conf/hue.service.keytab"
        uid: hue.user.name
        gid: hue.group.name

## SSL Client

      @call header: 'SSL Client', handler: ->
        hue.ca_bundle = '' unless hue.ssl.client_ca
        @file
          target: "#{hue.ca_bundle}"
          source: "#{hue.ssl.client_ca}"
          local_source: true
          if: !!hue.ssl.client_ca
        @file
          target: '/etc/init.d/hue'
          match: /^DAEMON="export REQUESTS_CA_BUNDLE='.*';\$DAEMON"$/m
          replace: "DAEMON=\"export REQUESTS_CA_BUNDLE='#{hue.ca_bundle}';$DAEMON\""
          append: /^DAEMON=.*$/m

## SSL Server

Upload and register the SSL certificate and private key respectively defined
by the "hdp.hue.ssl.certificate" and "hdp.hue.ssl.private_key" 
configuration properties. It follows the [official Hue Web Server 
Configuration][web]. The "hue" service is restarted if there was any 
changes.

      @call header: 'SSL Server', handler: ->
        @file.download
          source: hue.ssl.certificate
          target: "#{hue.conf_dir}/cert.pem"
          uid: hue.user.name
          gid: hue.group.name
        @file.download
          source: hue.ssl.private_key
          target: "#{hue.conf_dir}/key.pem"
          uid: hue.user.name
          gid: hue.group.name
        @file.ini
          target: "#{hue.conf_dir}/hue.ini"
          content: desktop:
            ssl_certificate: "#{hue.conf_dir}/cert.pem"
            ssl_private_key: "#{hue.conf_dir}/key.pem"
          merge: true
          parse: misc.ini.parse_multi_brackets 
          stringify: misc.ini.stringify_multi_brackets
          separator: '='
          comment: '#'
        @service
          name: 'hue'
          action: 'restart'
          if: -> @status -1

## Fix Banner

In the current version "2.5.1", the HTML of the banner is escaped.

      @call header: 'Fix Banner', handler: ->
        @file
          target: '/usr/lib/hue/desktop/core/src/desktop/templates/login.mako'
          match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
          replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
          bck: true
        @file
          target: '/usr/lib/hue/desktop/core/src/desktop/templates/common_header.mako'
          write: [
            match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
            replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
            bck: true
            ,
            match: /\.banner \{([\s\S]*?)\}/
            replace: ".banner {#{hue.banner_style}}"
            bck: true
            if: hue.banner_style
          ]

## Clean Temp Files

Clean up the "/tmp" from temporary Hue directories. All the directories which
modified time are older than 10 days will be removed.

      @cron_add
        header: 'Clean Temp Files'
        cmd: "find /tmp -maxdepth 1 -type d -mtime +10 -user #{hue.user.name} -exec rm {} \\;",
        when: '0 */19 * * *'
        user: "#{hue.user.name}"
        match: "\\/tmp .*-user #{hue.user.name}"
        exec: true
        if: hue.clean_tmp

## Dependencies

    misc = require 'mecano/lib/misc'

## Resources:   

*   [Official Hue website](http://gethue.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[web]: http://gethue.com/docs-3.5.0/manual.html#_web_server_configuration


# Druid Tranquility Install

    module.exports = header: 'Druid Tranquility Install', handler: ->
      {druid} = @config.ryba

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Tranquility | 8200 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8200, protocol: 'tcp', state: 'NEW', comment: "Druid Tranquility" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep druid
druid:x:2435:2435:druid User:/var/lib/druid:/bin/bash
cat /etc/group | grep druid
druid:x:2435:
```

      @group druid.group
      @user druid.user

## Packages

Download and unpack the release archive.

      @file.download
        header: 'Packages'
        source: "#{druid.tranquility.source}"
        target: "/var/tmp/#{path.basename druid.tranquility.source}"
      # TODO, could be improved
      # current implementation prevent any further attempt if download status is true and extract fails
      @extract
        source: "/var/tmp/#{path.basename druid.tranquility.source}"
        target: '/opt'
        if: -> @status -1
      @link
        source: "/opt/tranquility-distribution-#{druid.tranquility.version}"
        target: "#{druid.tranquility.dir}"
      @execute
        cmd: """
        if [ $(stat -c "%U" /opt/tranquility-distribution-#{druid.tranquility.version}) == '#{druid.user.name}' ]; then exit 3; fi
        chown -R #{druid.user.name}:#{druid.group.name} /opt/tranquility-distribution-#{druid.tranquility.version}
        """
        code_skipped: 3

## Dependencies

    path = require 'path'

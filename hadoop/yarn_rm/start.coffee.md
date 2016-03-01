
# Hadoop YARN ResourceManager Start

Start the ResourceManager server. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-resourcemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
```

    module.exports = header: 'Yarn RM Start', label_true: 'STARTED', handler: ->
      {yarn} = @config.ryba
      @remove
        destination: "#{yarn.pid_dir}/yarn-#{yarn.user.name}-resourcemanager.pid"
        if: @retry > 0
      @service_start
        name: 'hadoop-yarn-resourcemanager'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'

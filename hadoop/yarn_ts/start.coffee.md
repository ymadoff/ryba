
# YARN Timeline Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'

    module.exports.push name: 'YARN TS # Start', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir} = ctx.config.ryba
      ctx.execute
        # su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelineserver"
        cmd: """
        if pid=`cat /var/run/hadoop-yarn/yarn-yarn-timelineserver.pid`; then
          if ps -e -o pid | grep -v grep | grep -w $pid; then exit 3; fi; 
        fi;
        su -l #{yarn.user.name} -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} start timelineserver"
        echo $?
        """
        code_skipped: 3
      .then next
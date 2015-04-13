
# YARN Timeline Server Stop


    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'YARN TS # Stop', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir} = ctx.config.ryba
      ctx.execute
        # su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop timelineserver"
        cmd: """
        if pid=`cat /var/run/hadoop-yarn/yarn-yarn-timelineserver.pid`; then
          if ps -e -o pid | grep -v grep | grep -w $pid; then
            su -l #{yarn.user.name} -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} stop timelineserver"
          fi; 
        fi;
        exit 3;
        """
        code_skipped: 3
      , next
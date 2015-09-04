
# Yarn Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/hadoop/yarn_rm/wait'

## Check CLI

    module.exports.push name: 'YARN Client # Check CLI', label_true: 'CHECKED', handler: ->
      @execute
        cmd: mkcmd.test @, 'yarn application -list'

## Check Distributed Shell

The distributed shell is a yarn client application which submit a command or a
Shell script to be executed inside one or multiple YARN containers.

# http://riccomini.name/posts/hadoop/2013-06-14-yarn-with-cgroups/

    module.exports.push name: 'YARN Client # Check Distributed Shell', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check, user} = @config.ryba
      appname = "ryba_check_#{@config.shortname}_distributed_cache_#{Date.now()}"
      scriptpath = "#{user.home}/check_distributed_shell.sh"
      @write
        destination: "#{scriptpath}"
        content: """
        #!/usr/bin/env bash
        echo Ryba Ryba NM hostname: `hostname`
        """
        mode: 0o0640
      @execute
        cmd: mkcmd.test @, """
        yarn org.apache.hadoop.yarn.applications.distributedshell.Client \
          -jar /usr/hdp/current/hadoop-yarn-client/hadoop-yarn-applications-distributedshell.jar \
          -shell_script #{scriptpath} \
          -appname #{appname} \
          -num_containers 1
        # Valid states: ALL, NEW, NEW_SAVING, SUBMITTED, ACCEPTED, RUNNING, FINISHED, FAILED, KILLED 
        # Wait for application to run
        done_cmd="yarn application -list -appStates ALL | grep #{appname} | egrep 'FINISHED|FAILED|KILLED'"
        i=0; while [[ $i -lt 1000 ]] && [[ ! `$done_cmd` ]]; do ((i++)); sleep 1; done
        # Get application id
        application=`yarn application -list -appStates ALL | grep #{appname} | sed -e 's/^\\(application_[0-9_]\\+\\).*/\\1/'`
        if [ ! "$application" ]; then exit 1; fi
        rm=`yarn logs -applicationId $application 2>/dev/null | grep 'Ryba NM hostname' | sed 's/Ryba NM hostname: \\(.*\\)/\\1/'`
        [ "$rm" ]
        """
        not_if_exists: unless force_check then scriptpath

## Dependencies

    mkcmd = require '../../lib/mkcmd'

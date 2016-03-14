
# `hdfs_mkdir(options, callback)`

Create an HDFS directory.

Options include:

*   `destination`   
*   `krb5_user`   
*   `mode`   
*   `user`   
*   `group`   
*   `parent`   
*   `parent.mode`   
*   `parent.user`   
*   `parent.group`   

## Source Code

    module.exports = required: true, handler:  ->
      return if @registered 'hdfs_mkdir'
      @register 'hdfs_mkdir', (options, callback) ->
        throw callback Error "Required option: 'destination'" unless options.destination
        options.mode ?= ''
        options.mode = mode.stringify options.mode
        options.user ?= ''
        options.group ?= ''
        options.parent ?= {}
        options.parent.mode ?= options.mode
        options.parent.mode = mode.stringify options.parent.mode if options.parent.mode
        options.parent.user ?= options.user
        options.parent.group ?= options.group
        wrap = (cmd) ->
          return cmd unless options.krb5_user
          "echo '#{options.krb5_user.password}' | kinit #{options.krb5_user.principal} >/dev/null && {\n#{cmd}\n}"
        @execute
          cmd: wrap """
          target="#{options.destination}"
          if hdfs dfs -test -d $target; then
            # TODO: compare permissions and ownership
            exit 3;
          fi
          function create_dir {
            dir=$1
            mode=$2
            user=$3
            group=$4
            echo "Create dir $dir"
            hdfs dfs -mkdir $dir
            if [ -n "$mode" ]; then
              echo "Change permissions to $mode"
              hdfs dfs -chmod $mode $dir
            fi
            if [ -n "$user" ]; then
              echo "Change owner ownership to $user"
              hdfs dfs -chown $user $dir
            fi
            if [ -n "$group" ]; then
              echo "Change group ownership to $group"
              hdfs dfs -chgrp $group $dir
            fi
          }
          function create_parent_dir {
            local dir=`dirname $1`
            if [ $dir == "/" ]; then return; fi
            if hdfs dfs -test -d $dir; then return; fi
            create_parent_dir $dir
            # echo "Create parent directory: $dir"
            create_dir \
              "$dir" \
              "#{options.parent.mode or ''}" \
              "#{options.parent.user or ''}" \
              "#{options.parent.group or ''}"
          }
          create_parent_dir $target
          create_dir \
            $target \
            "#{options.mode or ''}" \
            "#{options.user or ''}" \
            "#{options.group or ''}"
          """
          code_skipped: 3
          trap_on_error: true
        .then callback
            
## Dependecies

    {mode} = require 'mecano/src/misc'

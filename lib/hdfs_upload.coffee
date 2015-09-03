
module.exports = (ctx) ->
  return if ctx.registered 'hdfs_upload'
  ctx.register 'hdfs_upload', (options, callback) ->
    return callback Error "Required option 'source'" unless options.source
    return callback Error "Required option 'target'" unless options.target
    options.lock ?= "/tmp/ryba-#{string.hash options.target}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      source=#{options.source}
      link=`echo $source | sed  's|\\(.*/hdp/current/[^/]*\\)/.*|\\1|'`
      version=`readlink $link | sed  's|.*/hdp/\\([^/]*\\)/.*|\\1|'`
      target=#{options.target}
      lock=#{options.lock}
      if hdfs dfs -mkdir $lock; then
        echo "Lock created"
      else
        echo 'lock exist, check if valid'
        timeout=240 # 4 minutes
        now=`date '+%s'`
        crdate=$(hdfs dfs -stat $lock | xargs -0 date '+%s' -d)
        if [ $(($now - $crdate)) -le $timeout ]; then
          sleep_time=$((240 - $crdate + $now + 5))
          echo crdate $crdate
          echo now $now
          echo sleep_time $sleep_time
          echo "Lock is active, wait for ${sleep_time}s until expiration"
          sleep $sleep_time
          if hdfs dfs -test -d $lock; then
            echo "Lock still present after waiting"
            exit 1
          fi
          if hdfs dfs -test -f $target; then
            echo "File uploaded in parallel by somebody else"
            exit 3
          fi
          echo "Lock released, attemp to upload file"
        else
          echo "Lock has expired $(($now - $crdate + $timeout))s ago, pursue uploading"
        fi
      fi
      echo "Upload file to $(dirname $target)"
      function create_parent_dir {
        local dir=`dirname $1`
        if [ $dir == "/" ]; then return; fi
        if hdfs dfs -test -d $dir; then return; fi
        create_parent_dir $dir
        echo "Create parent directory: $dir"
        hdfs dfs -mkdir -p $dir
        hdfs dfs -chmod -R 555 $dir
      }
      create_parent_dir $target
      hdfs dfs -copyFromLocal $source $(dirname $target)
      hdfs dfs -chmod -R 444 $target
      hdfs dfs -test -f $target
      hdfs dfs -rm -r $lock
      """
      trap_on_error: true
      code_skipped: 3
      not_if_exec: mkcmd.hdfs ctx, """
      source=#{options.source}
      link=`echo $source | sed  's|\\(.*/hdp/current/[^/]*\\)/.*|\\1|'`
      version=`readlink $link | sed  's|.*/hdp/\\([^/]*\\)/.*|\\1|'`
      target=#{options.target}
      hdfs dfs -test -f $target
      """
    .then callback

mkcmd = require './mkcmd'
{string} = require 'mecano/lib/misc'

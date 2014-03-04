
mkcmd = require './lib/mkcmd'

module.exports = []
module.exports.push 'phyla/core/nc'
module.exports.push 'phyla/hdp/mapred_client'
module.exports.push 'phyla/hdp/yarn_client'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('../core/nc').configure ctx
  ctx.config.hdp.pig_user ?= 'pig'
  ctx.config.hdp.pig_conf_dir ?= '/etc/pig/conf'

###
http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html
###
module.exports.push name: 'HDP Pig # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'pig'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Pig # Users', callback: (ctx, next) ->
  # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd pig -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop Pig service\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Pig # Configure', callback: (ctx, next) ->
  # Note, HDP default file comes without any config. We
  # could do the same, start with empty config object
  # that user could overwrite
  next null, ctx.PASS

module.exports.push name: 'HDP Pig # Env', callback: (ctx, next) ->
  {hadoop_group, pig_conf_dir, pig_user} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/files/pig/pig-env.sh"
    destination: "#{pig_conf_dir}/pig-env.sh"
    context: ctx
    local_source: true
    uid: pig_user
    gid: hadoop_group
    mode: 0o755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push name: 'HDP PIG # Check', callback: (ctx, next) ->
  rm = ctx.host_with_module 'phyla/hdp/yarn_rm'
  ctx.waitForConnection rm, 8050, (err) ->
    return next err if err
    ctx.execute
      cmd: mkcmd.test ctx, """
      if hdfs dfs -test -d /user/test/pig_#{ctx.config.host}/result; then exit 2; fi
      hdfs dfs -rm -r /user/test/pig_#{ctx.config.host}
      hdfs dfs -mkdir -p /user/test/pig_#{ctx.config.host}
      echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - /user/test/pig_#{ctx.config.host}/data
      """
      code_skipped: 2
    , (err, executed) ->
      return next err, ctx.PASS if err or not executed
      ctx.write
        content: """
        data = LOAD '/user/test/pig_#{ctx.config.host}/data' USING PigStorage(',') AS (text, number);
        result = foreach data generate UPPER(text), number+2;
        STORE result INTO '/user/test/pig_#{ctx.config.host}/result' USING PigStorage();
        """
        destination: '/home/test/test.pig'
      , (err, written) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          pig /home/test/test.pig
          rm -rf /home/test/test.pig
          hdfs dfs -test -d /user/test/pig_#{ctx.config.host}/result
          """
        , (err, executed) ->
          next err, ctx.OK


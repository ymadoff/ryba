

# ###
# Start Oozie
# -----
# Execute these commands on the Oozie server host machine
# ###
# module.exports.push (ctx, next) ->
#   {oozie_user, oozie_log_dir} = ctx.config.hdp
#   @name "HDP # Start Oozie host machine"
#   ctx.execute
#     cmd: "sudo su -l #{oozie_user} -c \"cd #{oozie_log_dir}; /usr/lib/oozie/bin/oozie-start.sh\""
#   , (err, executed) ->
#     next err, if executed then ctx.OK else ctx.PASS
## Check Hst Agent
        
Check the HST Agent host registration status
        
    module.exports = header: 'HST Agent Check', timeout: -1, label_true: 'CHECKED', handler: ->          
      @execute
        cmd: 'hst agent-status | grep registered'

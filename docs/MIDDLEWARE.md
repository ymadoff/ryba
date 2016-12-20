
# Write your own middleware

## Architecture

Ryba installs hadoop on each server component by component
The list and configuration for each server's components is placed in the ryba-cluster/conf/servers.coffee file.
Each module installed has its sources placed in the ryba root directory.
how does it work ?

Your can add the middleware you want to execute in the previous servers.coffee file/
Your module has to come as a directory that you will place inside the ryba directory.
For exemple if you want to install a module name myNewModule you will have to place a directory containg the sources
name 'myNewModule' and place it in ryba directory.
The result will be
/ryba/boostrap
/ryba/hadoop
/ryba/hbase
/ryba/myNewModule

Of course you can then divide your module in sub parts.

## Needed files

You have to specify which script ryba will execute in a file namede after your coponent and with the extension .coffee.md
So for our example the directory tree will be ryba
/ryba/boostrap/...
/ryba/boostrap/...
...
/ryba/myNewModule/myNewModule.coffee.md

Ryba will read it ( by default ) and see which script to execute for the different commands 
The different commands are :
  - prepare   
  - install   
  - start   
  - stop   
  - check   
  - status   
 For example if you have a script myNewModule_check.coffee.md which checks if the installation of your component is correct
 you have to export it in the module as 'check'  
   ```
   module.exports.push commands: 'check', modules: 'ryba/myNewModule/myNewModule_check.coffee'
   ```

 It works the same way if you want to execute several script for one command
    ```
    module.exports.push commands: 'install', modules: [
      'ryba/myNewModule/myNewModule_install.coffee'
      'ryba/myNewModule/myNewModule_check.coffee'
    ]

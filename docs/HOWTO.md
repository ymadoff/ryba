
# Getting started standard mode

You should have executed previous commands and instructions from README.md 
(installing nodejs for example) from ryba-cluster directory

To get started with ryba in standard mode, you need  mainly two modules
One module is the ryba itself, you can download the sources from https://github.com/ryba-io/ryba
The second is the ryba cluster configuration module that you cn download from https://github.com/ryba-io/ryba-cluster
Create a ryba directory for example and move the two downloaded directories in it.
One is ryba it self with the component it's going to install
The ryba cluster configuration contains the files which describe the cluster of
server you have and which component you want on each server.
The detail of each server and the component you want to install is placed in
ryba-cluster/conf/servers.coffee
If you want let the main configuration file you can give to ryba the -c argument
and the path to the enhanced configuration file
Launch the install after having cd into the directory named ryba
```bash
./bin/ryba install
```

## Working environment in development mode (optional)

Check the Readme Page from ryba-cluster
Working in development mode can be useful in order to test some configurations
or commands on a cluster ( at least 1 master node )
for this you can install Virtual machine on your computer and install haddop on it
In order to manage the most easily possible a cluster we are going to use Vagrant

Please check the official webpage for Vagrant installation process at https://www.vagrantup.com.
If you use a linux distribution, vagrant should be available from your package manager.

Once Vagrant is installed, please also install some additionnal modules
```
vagrant plugin install vagrant-share
vagrant plugin install vagrant-vbguest
```

And if you work behind a proxy

`vagrant plugin install vagrant-proxyconf`

The vagrant configuration file VagrantFile is located in the resources directory.
Vagrant MUST be executed from this directory. If you use a UNIX OS, you can use
the vagrant script for this purpose.

Configure proxy using the env var *VAGRANT\_HTTP\_PROXY*.
If you use proxy please set this variable :

On linux :
`export VAGRANT_HTTP_PROXY='http://user:password@proxyurl/'`

On windows :
`SET VAGRANT_HTTP_PROXY='http://user:password@proxyurl/'`

You need an image of centos6 in order to build from it the virtual machine
Be careful to indicate to vagrant the right name of the image in the folder resources/VagrantFile
`box = 'centos65-x86_64'`

VMs should have Vbox Guest Additions installed. The plugin vbguest is here to do
the job. There is two ways to configure it :
#### local

You have to have the addition iso file on your computer, corresponding to the
version of Virtualbox. You can manually download it or if you are on Linux, you
might let your package manager handle it for you.

then modify VagrantFile :
```
config.vbguest.iso_path=/path/to/VBoxGuestAdditions.iso
config.no_remote=true
```

#### Remote

You can let vbguest handle it for you, but your VM have to have an internet
connection. This is the default behaviour but here is the corresponding configuration.
`config.no_remote=false`

Now it is time to let Vagrant configure your VMs !
`/project_path/bin/vagrant up`

## Working environment in offline mode (optional)

The option to work offline is to have the needed repositories available whithout passing by the Internet
It's practical but also faster than working online
The thing is we need repositories which are only available from centos repositories
So we need Yum in order to get the good repositories
The steps are to :
  - download the repositories we will need from the yum one
  - set up a web server to make the repositories available on the development environment's network

To make this we are going to use docker.
We launch one container to download the needed repositories
Then we launch a container per repository which will serve as a web server for serving repository

Start by downloading ryba-repos from https://github.com/ryba-io/ryba-repos and name it ryba-repo

Then set up docker :

On linux:

You can install directly docker from your distribution installer

On windows and Mac OS X:

We are going to use boot2docker to run docker as if we were on linux
Download the installer from the offocial webpage and follow the instructions to install it


  Check if it correctly installed by typing in a terminal
  ```bash
  boot2docker -v
  ```
  then init boot2docker by typing ( it will create a  file named .profile in ~/.boot2docker/ )
  ```bash
  boot2docker init
   ```
  then put the following code in ~/.boot2docker/.profile
  NetMask = [255, 255, 255, 0]

  # host-only network DHCP server IP
  DHCPIP = "10.10.10.1"

  # host-only network DHCP server enabled
  DHCPEnabled = true

  # host-only network IP range lower bound
  LowerIP = "10.10.10.101"

  # host-only network IP range upper bound
  UpperIP = "10.10.10.110"

  than start docker by typing
  ```bash
  boot2docker up
  ```
  by typing the following command you will be able to see if it's running and the ip address of the VM
  ```bash
  boot2docker status
  boot2docker ip
  ```
  Then we actually create an alias to type docker as if we were on linux
  ```bash
  boot2docker up && $(boot2docker shellinit)
  ```

  You should be able to see a empty result from
  ```bash
  docker ps
   ```
  Then  start the repositories container downloader ( start and sync )
  To Do

  Then start the web server containers
  ```bash
  bin/repos start epel
  bin/repos start centos
  bin/repos start hdp-2.1.7.0
  bin/repos start hdp-2.2.0.0
  ```
   Re-try the following command  you should see the 4 containers
   ```bash
   docker ps
   ```
   now you can run ryba with the offline argument after having cd into ryba directory
   note: -c enables enhanced configuration
   ```bash
   ./bin/ryba -c ./conf/users/offline.coffee install
   ```

## Configuring ryba

The default configuration works with 6 servers 3 master 1 front and 2 workers
You can enhance the configuration , for this:

### Change the vagrant configuration

Of course if you change the configuration of the cluster you have to tell to
vagrant how much VM you want change the content of resources/VagrantFile to suit your needs
Take example from the set configuration

### Change the component composition of each server

Ryba needs to know what component will be installed on each server
You have to change the content of ryba-cluster/conf/servers.coffee in order to suit your needs
Do not try change the order of component
Be careful to let the security component for each server as it was written originally
(if you add server , add also the security component) take example from the set configuration

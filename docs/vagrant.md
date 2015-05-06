# Using Vagrant

If you want to install a working environment for ryba on your machine, you need to have vagrant installed. Vagrant is a open-source software designed to create and manage Virtual Machines. It is a wrapper that can use several back-ends (providers). Vagrant is available for OS X, Windows, and Linux.

Please check the official webpage for Vagrant installation process. If you use a linux distribution, vagrant should be available from your package manager.

You may want to use VirtualBox as the provider, but you can also use libvirt. Please refer to the Official Documentation. This guide Will detail both Virtualbox and libvirt configuration

## VirtualBox

You shoud first configure VirtualBox Network. Launch virtualbox GUI then

Files → Preferences → Network → Host Network → Add...

Then enter this configuration:
IPv4 address: 10.10.10.1
IPv4 netmask: 255.255.255.0

Once Vagrant is installed and Virtualbox is configured, please also install some additional modules:
```bash
vagrant plugin install vagrant-share
vagrant plugin install vagrant-vbguest
```

The vagrant configuration file Vagrantfile is located in the resources directory. Vagrant MUST be executed from this directory. If you use a UNIX OS, you can use the vagrant script for this purpose.

Now you need to download a vagrant box to get started.
To download the box corresponding to our default working environment (CentOS 6.5) :
```bash
vagrant add 'centos65-x86_64-50g' 'https://googledrive.com/host/0B4tZlTbOXHYWVGpHRWZuTThGVUE/centos65_virtualbox_50G.box'
```

Please check in the resources/Vagrantfile that the 'box' corresponds to the name of the box you want to use.
In the previous example :
```ruby
box='centos65-x86_64-50g'
```

VMs should have Vbox Guest Additions installed. The plugin vbguest is here to do the job. There is two ways to configure it :

### Local

You have to have the addition iso file on your computer, corresponding to the version of Virtualbox. You can manually download it or if you are on Linux, you might let your package manager handle it for you.

then modify Vagrantfile :
```ruby
config.vbguest.iso_path=/path/to/VBoxGuestAdditions.iso
config.no_remote=true
```

### Remote

You can let vbguest handle it for you, but your VM have to have an internet connection. This is the default behaviour but here is the corresponding configuration.
```ruby
config.no_remote=false
```

Now it is time to let Vagrant configure your VMs !
```bash
/project_path/bin/vagrant up --provider=virtualbox
```

Note that the provider parameter is optional since virtualbox is the default provider

Your environment is now ready for ryba.

### Known Issues

## Libvirt

Libvirt can be used for performance purpose. Libvirt is a wrapper for QEMU, QEMU/KVM, VMWare, Xen, ESX, etc. Only QEMU and QEMU/KVM have been tested, but other back-end should also work.

You shoud first configure Libvirt Network. Launch virt-manager GUI then configure a backend:

Files → Add connection

double-click on the new entry in the backend list, then

Virtual Networks → Add ...
  IPv4 address: 10.10.10.1/24
  ☑ Activate DHCPv4
  start: 10.10.10.100
   end : 10.10.10.254

Storage → Add ... → ryba-cluster

Once Vagrant is installed and libvirt is configured, please also install some additional modules:
```bash
CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib64" vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-mutate
```

The vagrant configuration file Vagrantfile is located in the resources directory. Vagrant MUST be executed from this directory. If you use a UNIX OS, you can use the vagrant script for this purpose.

Now you need to download a vagrant box to get started.
Download the box corresponding to our default working environment (CentOS 6.5) :
```bash
vagrant add 'centos65-x86_64-50g' 'https://googledrive.com/host/0B4tZlTbOXHYWVGpHRWZuTThGVUE/centos65_virtualbox_50G.box'
vagrant mutate 'centos65-x86_64-50g' libvirt
```

Please check in the resources/Vagrantfile that the 'box' corresponds to the name of the box you want to use.
In the previous example :
```ruby
box='centos65-x86_64-50g'
```

Now it is time to let Vagrant configure your VMs !
```bash
/project_path/bin/vagrant up --provider=libvirt
```

Note that the provider parameter is MANDATORY since virtualbox is the default provider

Your environment is now ready for ryba.

### Known Issues

If you get this error:
```
undefined method `active?' for #<Libvirt::Domain:0x00000003255c08>
```
Please do:
```bash
vagrant plugin uninstall vagrant-libvirt

sudo mv /opt/vagrant/embedded/lib/libcurl.so{,.backup}
sudo mv /opt/vagrant/embedded/lib/libcurl.so.4{,.backup}
sudo mv /opt/vagrant/embedded/lib/libcurl.so.4.3.0{,.backup}
sudo mv /opt/vagrant/embedded/lib/pkgconfig/libcurl.pc{,.backup}

CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib" vagrant plugin install vagrant-libvirt

sudo mv /opt/vagrant/embedded/lib/libcurl.so{.backup,}
sudo mv /opt/vagrant/embedded/lib/libcurl.so.4{.backup,}
sudo mv /opt/vagrant/embedded/lib/libcurl.so.4.3.0{.backup,}
sudo mv /opt/vagrant/embedded/lib/pkgconfig/libcurl.pc{.backup,}
```

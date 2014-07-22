

Ryba boostraps and manages a full secured Hadoop cluster with one command. This is
an OSS project released under the [new BSD license][license] developed for one
of the largest utility company and now operationnal.

Ryba is our answer to DevOps integration need for product delivery and quality
testing. It provides the flexibilty to answer the demand of your internal 
information technology (IT) operations team. It is written in JavaScript and
CoffeeScript to facilitate and accelerate feature development and maintenance 
releases. The language encourages self-documented code, look by yourself the
source code deploying two [HA namenodes][hdfs_nn].

Install Ryba locally or on a remote server and you are ready to go. It uses SSH to
connect to each server of your cluster and will fully install all the components
you wish. You don't need to prepare your cluster nodes as long as a minimal 
installation of RHEL or CentOS is installed with a root user or a user with sudo
access.

## Ryba motivations

-   Use secured comminication with SSH
-   No database used, full distributing across multiple servers relying on GIT
-   No agent or pre-installation required on your cluster nodes
-   Version control all your configuration and modifications (using GIT by default)
-   Command-based to integrate with your [Business Continuity Plan (BCP)][bcp] and existing scripts
-   For developer, as simple as learning Node.js and not a new framework
-   Self-documented code written in [Literate CoffeeScript ][literate]
-   Idempotent and executable on a running cluster without any negative impact

## Ryba features

-   Bootstrap the nodes from a fresh install
-   Configure proxy environment if needed
-   Optionnaly create a bind server (useful in Vagrant development environment)
-   Install OpenLDAP and Kerberos and/or integrate with your existing infrastructure
-   Deploy the latest Hortonworks Data Platform (HDP)
-   Setup High Availabity for HDFS
-   Integrate Kerberos with cross realm support
-   Set IPTables rules and startup scripts
-   Check the running components
-   Provide convenient utilities such as global start/stop/status commands, 
    distributed shell execution, ...

Installation
------------

### Node.js

First download Node.js. You might need to adjust the name of the Node.js archive depending on the version you choose to install. Also, replace the path "/usr/local/node" to another location (eg "~/node") if you don't have the permission to write inside "/usr/local".

```bash
# Extract the Node.js package
tar xzf node-v0.10.28-linux-x64.tar.gz
# Move Node.js into its final destination
sudo mv node-v0.10.28-linux-x64 /usr/local/node
# Add path to Node.js binary
echo 'export PATH=/usr/local/node/bin:$PATH' >> ~/.bashrc
# Source the update profile
. ~/.bashrc
# Check if node is installed
node -v
# Clean up uploaded archive
rm -rf node-v0.10.28-linux-x64.tar.gz
```

If you are behind a proxy, configure the [Node.js Pakage Manager (NPM)][npm] with
the commands:

```bash
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080
```

### Ryba

Run `npm install` to download the project dependencies. 

Contributors
------------

*   David Worms: <https://github.com/wdavidw>

[npm]: https://www.npmjs.org/
[masson]: https://github.com/wdavidw/node-masson
[license]: https://github.com/wdavidw/ryba/blob/master/LICENSE.md
[hdfs_nn]: https://github.com/wdavidw/ryba/blob/master/hadoop/hdfs_nn.coffee.md
[bcp]: http://en.wikipedia.org/wiki/Business_continuity_planning
[literate]: http://coffeescript.org/#literate





# Development

Describe how to set up a development environment with the help of NPM.

## Node.js Virtual Environments

A virtual environment manage multiple version of Node.js insiude your host
machine to quicky switch from one version to another one.

Using a virtual environment isnt required but recommanded. There are multiple
solutions available. The most popular are:

*   [nvm](https://github.com/creationix/nvm)
*   [nave](https://github.com/isaacs/nave)
*   [n](https://github.com/tj/n)

## Install the sources

Because Ryba rely heavily on Masson and Mecano, chances are that while
developing/modifying Ryba you also wish to improve Masson and Mecano as well.
For this reason, this procedure explains you how to setup a full development
environment with those modules as well.

Comprehensive link between the package dependencies is leveraging [npm] and more
specifically the `npm link` command.

### Set a root folder

```
PROJECTS_HOME='~/projects'
```

### Setup mecano

```
cd $PROJECTS_HOME
git clone https://github.com/wdavidw/node-mecano mecano
cd mecano
npm install
npm link
```

### Setup masson

```
cd $PROJECTS_HOME
git clone https://github.com/wdavidw/node-masson masson
cd masson
npm install
npm link mecano
npm link
```

### Setup ryba

```
cd $PROJECTS_HOME
git clone https://github.com/ryba-io/ryba ryba
cd ryba
npm install
npm link mecano
npm link ryba
npm link
```

### Setup ryba-cluster (or ryba-single)

```
cd $PROJECTS_HOME
git clone https://github.com/ryba-io/ryba-cluster ryba-cluster
cd ryba-cluster
npm install
npm link masson
npm link ryba
npm link
```

[nvm]: https://github.com/creationix/nvm
[nave]: https://github.com/isaacs/nave
[n]: https://github.com/tj/n
[npm]: https://github.com/npm/npm




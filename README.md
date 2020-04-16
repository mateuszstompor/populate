# populate

## Aim
While developing an app which runs on bare metal nodes in a cluster there is need to copy a package to all nodes and then perform installation. Common way to acheive it is to use ansiable. Unfortunately, network tends to be overloaded these days and ansible lags behind in comparison to invocation of a few `ssh` and `scp` commands.

## Why you should even care?
There are two main benefits. First of all you don't need to write installation scripts on your own. Secondly, it's quite fast. Copying and installation is made in parallel.

## Requirements
### System
* CentOS
* RHEL
### Packages
* git
* bash
* rpm

## Running
The program itself is simple. Doesn't support any options. Provide path to the `.rpm` file as the first argument.
Keep it mind that `populate` can be invoked from any node on which it was installed.
```
populate <file.rpm>
```

## Installation
To perform the installation you must execute the line below on a machine that has access to all machines in the cluster. 

```bash
rm -rf populate && git clone https://github.com/mateuszstompor/populate.git && cd populate && ./install.sh && cd .. && rm -rf ./populate
```

You will be asked to provide hostnames of nodes in the cluster

```
Enter hostnames of nodes in the cluster. 
Provide them as space separated words in a single line
```
Script checks if nodes are pingable and ask for the username used to access the nodes.
Bare in mind that communication with the nodes should be passwordless.

```
Provide user to log over ssh
```
Installation script will validate your config and copy the program to all nodes
```
Checking ssh conectivity...
localhost can be accessed
SSHABLE hosts localhost
Populating the script
********** SUCCESS **********
```


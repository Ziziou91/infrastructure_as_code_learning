# Infrastructure as Code

So far we've been able to automate multiple tasks with jenkins, such as testing and integration, but there are some things we still have do manually. Currently we need to manually launch our EC2 instances before we can deploy our code. **Infrastructure as code** gives us a way to launch virtual machines, and associates cloud services, through **orchestration**. We can specify the conditions and constants with a **configuration file**, typically written in YAML. 

A popular suite of tools for infrastructure as code is Ansible - alternatives include terraform, chef, puppet, cloudformation (AWS only and paid for).

## Configuration management using Ansible

Ansible is a powerful, agentless, open-source suite of infrastucture tools. It uses the human-readable programming language YAML to specify cloud configuration.

YAML is used by many IaC tools, including Docker & Kubernetes, so is a valuable tool to have at our use.

Ansible architecture features an Ansible controller and it's agent nodes. These will be their own AWS EC2 instances. it's wise to test the connections between these machines before doing anything else.

### Guide to setting up our Ansible controller and agents

1) Launch 3 EC2 instances. These will be our Ansible Controller, App and DB. Use Ubuntu 18.04
   1) tech258-name-ansible-controller
   2) tech258-name-ansible-app
   3) tech258-name-ansible-db
2) SSH into each instance and run `sudo apt-get update -y` and `sudo apt-get upgrade -y`
3) Back on the controller instance run the following commands
   1) `sudo apt-get install software-properties-common`
   2) `sudo apt-add-repository ppa:ansible/ansible`
   3) `sudo apt-get update`
   4) `sudo apt-get install ansible -y`
4) We can check our ansible installation was successful by running `sudo ansible --version`
5) Copy the ssh private key onto the Ansible controller vm, either using scp or nano
6) Change permissions on the key
```shell
chmod 400 key.pem
```
1) ssh from controller to the other vms to check SSH works.
2) cd into /ect/ansible and then nano into `hosts`. Add the following:
```shell
[web]
ec2-instance-app ansible_host=IP_ADRESS ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/KEY.pem

[db]
ec2-instance-db ansible_host=IP_ADRESS ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/KEY.pem
```

## interacting with Ansible agent nodes

Before we install anything on our agent nodes we need to know more about them. Things like OS, remianing available storage ect, are usfeul to know before we do anything. We can achieve this with
```shell
# print os version
sudo ansible web -a "uname -a"

# print available memory
sudo ansible web -a "free"

# print time on instance
sudo ansible all -a "date"

# update all agent nodes
sudo ansible all -a "sudo apt-get update -y" 

# see all files in user directory on all agent nodes
sudo ansible all -a "ls -a"
```

## Writing YAML

Getting indentation right in YAML is important. Everything needs to be correctly blocked. Instead of using tab in VS code use double space. Example:

```yml
- block starts here

  this is part of the same block as it's double spaced
```

## Installing nginx on our app server with an ansible playbook file

```yml
# creating a playbook to install/configure nginx on the web server
---
# YAML starts with three dashes - also allows applications to recognise steps (demarkated with ---), as well as YAML code in text files

# add the name of the host web (already defined in hosts)
- hosts: web
# see the logs while the script is running so we can see the result
  gather_facts: yes
# provide admin access - sudo
  become: true
# add instructions to install nginx on the web server
  tasks:
  - name: Installing Nginx web server
    apt: pkg=nginx state=present
# ensure nginx is in a running state
```
### Installing our web server app onto our agent node

Pseudocode
```yml
---
# add the name of the host web (already defined in hosts)
# see the logs while the script is running so we can see the result
# provide admin access - sudo
# outline tasks
## task 1 - run update and upgrade
## task 2 - install nxginx
## task 3 - install node
## task 4 - install npm
## task 5 - install git
## task 6 - clone app
## task 7 - install pm2
## task 8 - launch app with pm2

```
**instlal-app-play.yml**
```yml

```


TODO: Create a playbook to install nodejs on the web server. Migrate the app code, install dependencies and run the app in the background. 
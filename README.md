# SysOPS test @ Marfeel

## What I used @ home

1. Linux Debian buster as base system
2. Ansible
3. awscli tools


## Overview

This project is made for the test @ Marfeel.


## Before firing up
  - Change context from whatever region you're working on to eu-west-1
  - Fire initial wizard of vpc if it's not created
  - Setup vpc-sg for ec2 (22/80 to any)
  - Create IAM role to allow actions from haproxy instance, You must ASSING THAT TO THE INSTANCE
  - Create a new pair under ec2/secret-keys and download it
  - Setup the ips on ansible hosts files


## Getting started

  The first step is to clone repo on the disk, adding the required key :)

```
  $ eval `ssh-agent`
  $ ssh-add key-test.pem
```

## Running it all

  You must run first ansible for pre-loading:

    - haproxy
    - Base image

  HOW: 
```  
    - $ ansible-playbook playbook-img.yml -i hosts-img -u ubuntu
    - $ ansible-playbook playbook-haproxy.yml -i hosts-haproxy -u ubuntu
```
Sorry, my first time, respect my clumsyness :)

## Comments
Working on this been a total new way for working, never used ansible for a personal/test project. A total Yay/fail during two days :)

Using haproxy as load balancer and not aws ELB for detecting/Drain/add/wtv... for instances been really fun creating the script.

I spend a lot of time playing on Awscli, learning ansible, toying with haproxy and its api that I never used before (I did not used for this), just for curiosity. Been really fun :).

Take note that I'm not fluent in ansible, I did the best I could reading documentation by myself in 1 night, I'm sure it can be done better. Even doing the pre-setting on aws (vpcs, sg, keys, iams,...).

I've set up this repo the best way I could preserving some "logic" to be nice to read fast.

## Questions Answered

- Why do you think different cache times for the nginx cache and for the browser...

I asume that application could be down and a different cache must be set, if a deploy happen the app would be down and show a 503/504 error and that's ugly.

The static cache I feel it is too low even for google "pagespeed".

- Which is the AMI id you created?


- Which code you added to user-data? 

I cheated during test, I did not completely delete /opt/test/ contents, I wiped out the full directory I was trying to do it simple all the time. Sorry.

```
#!/bin/bash

git clone https://bitbucket.org/Marfeel/appserverpythontestapp/get/master.tar.gz /opt/test

```


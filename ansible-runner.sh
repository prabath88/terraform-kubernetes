#!/bin/bash

eval $(ssh-agent -s)
ssh-add /home/ec2-user/.ssh/ansible_key
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i /home/ec2-user/instant-kubernetes/hosts /home/ec2-user/instant-kubernetes/prerequisite.yaml
sleep 1
ansible-playbook -i /home/ec2-user/instant-kubernetes/hosts /home/ec2-user/instant-kubernetes/master.yaml
sleep 1
ansible-playbook -i /home/ec2-user/instant-kubernetes/hosts /home/ec2-user/instant-kubernetes/minion.yaml
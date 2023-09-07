#!/bin/bash

sudo scp -i tf-key-pair.pem tf-key-pair.pem  ubuntu@$1:/home/ubuntu

sudo ssh -i tf-key-pair.pem ubuntu@$1  "echo -e Public Server;ping -c 4 google.com;sudo ssh -i tf-key-pair.pem ubuntu@$2 'echo private server;ping -c 4 google.com | tee temp.txt;hostname >> temp.txt';sudo scp -i tf-key-pair.pem ubuntu@$2:/home/ubuntu/temp.txt ."
sudo scp -i tf-key-pair.pem ubuntu@$1:/home/ubuntu/temp.txt .
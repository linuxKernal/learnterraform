#!/bin/bash

sudo scp -i tf-key-pair.pem tf-key-pair.pem  ubuntu@$1:/home/ubuntu

sudo ssh -i tf-key-pair.pem ubuntu@$1  "echo -e Public Server;ping -c 4 google.com;sudo ssh -i tf-key-pair.pem ubuntu@$2 'echo private server;ping -c 4 google.com | tee temp.txt;hostname >> temp.txt';sudo scp -i tf-key-pair.pem ubuntu@$2:/home/ubuntu/temp.txt ."
sudo scp -i tf-key-pair.pem ubuntu@$1:/home/ubuntu/temp.txt .


# user_data              = <<-EOF
#     #!/bin/bash
#     sudo apt update
#     sudo apt upgrade -y
#     sudo apt install python3-pip
#     pip install psycopg2-binary
#     git clone https://github.com/linuxKernal/newcodespace.git
#     cd ~/newcodespace
#     git switch linux-cron-python
#     git checkout 5aa85b8
#     EOF
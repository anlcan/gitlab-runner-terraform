#!/usr/bin/env bash

curl -sSL https://get.docker.com/ | sh

curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
sudo apt update

sudo apt-get -y install gitlab-runner
sudo usermod -aG docker gitlab-runner
sudo -u gitlab-runner -H docker info
sudo apt install -y awscli jq ansible default-jdk maven unzip

# https://stackoverflow.com/a/5955623/203299
sudo sed -i -e '/concurrent =/ s/= .*/= 6/' /etc/gitlab-runner/config.toml


while IFS='' read -r token  || [[ -n "$token" ]]; do
    sudo gitlab-runner register -r ${token} --limit 2 --executor shell -u https://gitlab.com/ -n --name gitlab-loves-tf
done < ${1}



echo "running verify..."
sudo gitlab-runner verify --delete

echo "restarting..."
sudo gitlab-runner restart
Running gitlab-runner cmd:


    terraform {plan|apply|destroy} -var-file=`pwd`/secrets/finleap/secrets.tfvars  stacks/gitlab-runner 

where 
    - secrets.tfvars contains `access_key` and `secret_key`
    - inventory-checker-credentials is aws credentials file for deployment
    - tokens.txt is a text file with gitlab project id in each line
    - ssh_keys.zip is a zip file containing all the <client>-<environment>-ssh.pem files
    
    terraform apply -var-file=`pwd`/secrets/finleap/secrets.tfvars  stacks/gitlab-runner 

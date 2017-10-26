- Update `gitlab.tfvars`
- Update tokens.txt with registration tokens for your projects found under `/settings/ci_cd`, one per line
- Running gitlab-runner cmd:
  terraform apply --var-file=gitlab.tfvars  


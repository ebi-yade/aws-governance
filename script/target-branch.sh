#!/bin/bash
set -eu


is_hotfix=$(git branch --show-current | perl -ne 'print "false" if !/^hotfix\//')

if [[ ${is_hotfix} == 'false' ]]; then
  echo main
  exit 0
fi


response_out_file=/tmp/release-$(echo ${REPO} | sed -e "s/\//-/g" )-$(date +%s)
curl --silent --location "https://api.github.com/repos/${REPO}/releases/latest" -o ${response_out_file}
message=$(cat ${response_out_file} | jq -r ".message" )

if [[ ${message} != 'null' ]]; then
  echo main
else
  version=$(cat ${response_out_file} | jq -r '.tag_name' | perl -pe 's/^v(\d+).*+/\1/g;')
  git branch --format='%(refname:short)' \
  | perl -ne "BEGIN{\$branch=\"main\"; \$flag=0} if (\$flag==0 && /^stable-${version}\$/) {\$branch=\$_; \$flag=1} END{print \$branch}"
fi

exit 0

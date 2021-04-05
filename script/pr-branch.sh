#!/bin/bash
set -eu


pr_out_file=/tmp/pr-$(echo "${REPO}" | sed -e "s/\//-/g" )-$(date +%s)
curl --silent --location "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}" -o "${pr_out_file}"
message=$(jq -r ".message" "${pr_out_file}" )

if [[ ${message} != 'null' ]]; then
  echo "something wrong: ${message}"
  exit 1
else
  jq -jr '.base.ref,"...",.head.ref' "${pr_out_file}"
  exit 0
fi

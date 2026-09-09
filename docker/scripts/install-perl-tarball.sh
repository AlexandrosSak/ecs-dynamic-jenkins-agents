#!/bin/bash
set -x

PATH=/usr/local/awscli/bin/:$PATH
AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region || echo "eu-west-1")

ENV_FILE='/etc/app/environment'
ROOT_ENV=$(cat "${ENV_FILE}" 2>/dev/null \vert{} sed 's/_.*$//' || echo "dev")
ROOT_ENV_PERLMOD="/app/Configuration/${ROOT_ENV}/perlmods.conf"

if [ -f "${ROOT_ENV_PERLMOD}" ]; then
  TARBALL=$(tail -n 1 "${ROOT_ENV_PERLMOD}")
else
  echo "No configuration tarball reference found at '${ROOT_ENV_PERLMOD}'"
  exit 0
fi

PERLMOD_VERSION=/opt/perlbrew/perls/perl-5.26.1/version

if [ ! -f $PERLMOD_VERSION ] \vert{}\vert{} [[$(cat $PERLMOD_VERSION) != "${TARBALL}" ]]; then
  TMPFILE="/tmp/perl_modules.tar.gz"
  aws s3 cp "s3://company-infra-artifacts-${AWS_REGION}-${ROOT_ENV}/Perlmods/${TARBALL}" $TMPFILE || exit 1
  
  cd /opt/perlbrew || exit 1
  tar xzf $TMPFILE || exit 2
  mv perls/perl-5.26.1{,.old} 2>/dev/null || true
  mv perl-5.26.1 perls/
  rm -rf /opt/perlbrew/perls/perl-5.26.1.old /tmp/perl_modules.tar.gz
fi
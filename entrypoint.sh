#!/bin/bash
set -e
#set -x
#set -v

# Used in ci/cd pipeline.
# This script will upsert route53 healthcheck's to support multivalue dns.
USE_INGRESS="${USE_INGRESS:-true}"
if [ $USE_INGRESS = true ]; then
  DOMAIN=`yq '.spec.tls[0].hosts[0]' "${CONFIG_FILE}" | grep -v null | grep -v '\-' | head -n 1`
else
  DOMAIN=`yq '.metadata.annotations["external-dns.alpha.kubernetes.io/hostname"]' "${CONFIG_FILE}" | grep -v 'null' | grep -v '-' | head -n 1`
fi

IS_HTTPS="${IS_HTTPS:-true}"
if [ $IS_HTTPS = true ]; then
  TYPE="HTTPS"
else
  TYPE="HTTP"
fi

echo "DOMAIN $DOMAIN"
DOMAIN_ESCAPED=`echo $DOMAIN | sed 's/\./-/g'`
echo "DOMAIN_ESCAPED $DOMAIN_ESCAPED"
if [ $USE_INGRESS = true ]; then
  LB_IP=`kubectl get services --namespace ingress-nginx ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`
else
  LB_IP=`kubectl get services --namespace apm --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'`
fi

echo "LB_IP $LB_IP"
LB_IP_ESCAPED=`echo $LB_IP | sed 's/\./-/g'`
echo "LB_IP_ESCAPED $LB_IP_ESCAPED"
CALLER_REFERENCE=$DOMAIN_ESCAPED-$LB_IP_ESCAPED
echo "CALLER_REFERENCE $CALLER_REFERENCE"
uniq=$(dbus-uuidgen)
HEALTH_CHECK_ID=`aws route53 list-health-checks --query "HealthChecks[?HealthCheckConfig.FullyQualifiedDomainName=='$DOMAIN' && HealthCheckConfig.IPAddress=='$LB_IP']" | jq ".[].Id"`

if [ -z "$HEALTH_CHECK_ID" ]
then
    echo "creating healthe check config for ${LB_IP} and ${DOMAIN}"
    echo "{
        \"IPAddress\": \"${LB_IP}\",
        \"Port\": ${PORT:-443},
        \"Type\": \"${TYPE}\",
        \"ResourcePath\": \"/healthcheck\",
        \"FullyQualifiedDomainName\": \"$DOMAIN\",
        \"RequestInterval\": 30,
        \"FailureThreshold\": 3
    }" > /tmp/request.json
    echo ${uniq}
    HEALTH_CHECK_ID=`aws route53 create-health-check --caller-reference ${uniq} --health-check-config file:///tmp/request.json --output json | jq '.HealthCheck.Id'`
    CLEAN_HEALTH_CHECK_ID=`echo $HEALTH_CHECK_ID | sed s/\"//g`
    HCDate=$(date +"%d/%m/%Y_%H:%I:%M")
    aws route53 change-tags-for-resource --resource-type healthcheck --resource-id ${CLEAN_HEALTH_CHECK_ID} --add-tags Key=Name,Value=${CALLER_REFERENCE} Key=Date,Value="${HCDate}"
else
    CLEAN_HEALTH_CHECK_ID=`echo $HEALTH_CHECK_ID | sed s/\"//g`
fi

#echo "::set-output name=HEALTH_CHECK_ID::$HEALTH_CHECK_ID"
sed -i 's|<DNS_IDENTIFIER>|'${CLEAN_HEALTH_CHECK_ID}'|' ${CONFIG_FILE}


#cat ${CONFIG_FILE}
#echo "HEALTH_CHECK_ID=$HEALTH_CHECK_ID" >> $GITHUB_ENV

#echo $HEALTH_CHECK_ID
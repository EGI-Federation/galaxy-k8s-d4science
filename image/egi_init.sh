#!/bin/bash

/galaxy_venv/bin/generate_tools \
    --config /galaxy-central/config/tool_conf.xml \
    --outdir /galaxy-central/tools/d4science/ \
    --token /etc/d4science/admin-token/admin_token > /tmp/tool_conf.xml \
    && mv /tmp/tool_conf.xml /galaxy-central/config/tool_conf.xml

# Make sure Galaxy is at the right location, without using PROXY_PREFIX that would break
# our authentication

if [ "x$EGI_PROXY_PREFIX" != "x" ] 
    then
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  module:' state=absent" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  socket:' state=absent" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  mount:' state=absent" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  manage-script-name:' state=absent" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  manage-script-name: true'" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  mount: ${EGI_PROXY_PREFIX}=d4science_galaxy_authn.auth:galaxy_app()'" &> /dev/null
    ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  socket: unix:///srv/galaxy/var/uwsgi.sock'" &> /dev/null

    # Also set SCRIPT_NAME. It's not always necessary due to manage-script-name: true in galaxy.yml, but it makes life easier in this container + it does no harm
    ansible localhost -m lineinfile -a "path=/etc/nginx/conf.d/uwsgi.conf regexp='^    uwsgi_param SCRIPT_NAME' state=absent" &> /dev/null
    ansible localhost -m lineinfile -a "path=/etc/nginx/conf.d/uwsgi.conf insertafter='^    include uwsgi_params' line='    uwsgi_param SCRIPT_NAME ${EGI_PROXY_PREFIX};'" &> /dev/null

    ansible localhost -m lineinfile -a "path=/etc/nginx/nginx.conf regexp='^        location /etc/galaxy/web {$' line='        location ${EGI_PROXY_PREFIX}/etc/galaxy/web {'" &> /dev/null

    ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_DIR}/reports_wsgi.ini section=filter:proxy-prefix option=prefix value=${EGI_PROXY_PREFIX}/reports" &> /dev/null
    ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_DIR}/reports_wsgi.ini section=app:main option=filter-with value=proxy-prefix" &> /dev/null

    # Fix path to html assets
    ansible localhost -m replace -a "dest=$GALAXY_CONFIG_DIR/web/welcome.html regexp='(href=\"|\')[/\\w]*(/static)' replace='\\1${EGI_PROXY_PREFIX}\\2'" &> /dev/null

    # Set some other vars based on that prefix
    if [ "x$GALAXY_CONFIG_COOKIE_PATH" == "x" ]
        then
        export GALAXY_CONFIG_COOKIE_PATH="$EGI_PROXY_PREFIX"
    fi
    if [ "x$GALAXY_CONFIG_DYNAMIC_PROXY_PREFIX" == "x" ]
        then
        export GALAXY_CONFIG_DYNAMIC_PROXY_PREFIX="$EGI_PROXY_PREFIX/gie_proxy"
    fi

    # Change the defaults nginx upload/x-accel paths
    if [ "$GALAXY_CONFIG_NGINX_UPLOAD_PATH" == "/_upload" ]
        then
            export GALAXY_CONFIG_NGINX_UPLOAD_PATH="${EGI_PROXY_PREFIX}${GALAXY_CONFIG_NGINX_UPLOAD_PATH}"
    fi
fi

exec "$@"

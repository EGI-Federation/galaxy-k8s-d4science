FROM bgruening/galaxy-stable:19.01

RUN mkdir -p /etc/d4science \
             /galaxy-central/tools/d4science/ \
    && chown -R galaxy:galaxy /etc/d4science \
             /galaxy-central/tools/d4science/

COPY call-wps.sh /galaxy-central/tools/d4science/call-wps.sh
COPY extract.sh /galaxy-central/tools/d4science/extract.sh
COPY extract.xml /galaxy-central/tools/d4science/extract.xml

RUN cp /galaxy-central/config/tool_conf.xml.sample /galaxy-central/config/tool_conf.xml

RUN /galaxy_venv/bin/pip install \
    git+https://github.com/enolfc/d4science-galaxy-authn.git \
    git+https://github.com/enolfc/galaxy-dataminer.git \
    OWSLib==0.17.1

RUN ansible localhost -m lineinfile \
    -a "path=/etc/galaxy/galaxy.yml regexp='^  module:' line='  module: d4science_galaxy_authn.auth:galaxy_app()'"

RUN ansible localhost -m lineinfile \
    -a "path=/etc/nginx/nginx.conf insertafter='listen 80;' line='add_header Content-Security-Policy \"frame-ancestors https://*.d4science.org \'self\'\";'"

RUN ansible localhost -m cron \
    -a "name='refresh tools' hour='11' minute='00' job='/galaxy_venv/bin/generate_tools --config /galaxy-central/config/tool_conf.xml --outdir /galaxy-central/tools/d4science/ --token /etc/d4science/admin-token/admin_token > /tmp/tool_conf.xml && mv /tmp/tool_conf.xml /galaxy-central/config/tool_conf.xml'"

COPY welcome.html $GALAXY_CONFIG_DIR/web/welcome.html
COPY welcome_image.jpg $GALAXY_CONFIG_DIR/web/welcome_image.jpg 

COPY egi_init.sh /usr/local/bin/egi_init.sh
RUN chmod +x /usr/local/bin/egi_init.sh

ENTRYPOINT ["/usr/local/bin/egi_init.sh"]

CMD ["/usr/bin/startup"]

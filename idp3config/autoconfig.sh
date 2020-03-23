source /etc/profile

# config httpd
\cp -f /opt/inst/idp3config/httpd.conf /etc/httpd/conf/httpd.conf
\cp -f /opt/inst/idp3config/index.html /var/www/html/index.html
\cp -f /opt/inst/idp3config/ports.conf /etc/httpd/conf.d/ports.conf
mkdir /var/www/html/auditlog
\cp -f /opt/inst/idp3config/auditlog.sh /var/www/html/auditlog/auditlog.sh

# config tomcat
\cp -f /opt/inst/idp3config/idp.xml /etc/tomcat/Catalina/localhost/idp.xml
\cp -f /opt/inst/idp3config/server.xml /etc/tomcat/server.xml
\cp -f /opt/inst/idp3config/javax.servlet.jsp.jstl-api-1.2.1.jar /usr/share/tomcat/lib/javax.servlet.jsp.jstl-api-1.2.1.jar
\cp -f /opt/inst/idp3config/javax.servlet.jsp.jstl-1.2.1.jar /usr/share/tomcat/lib/javax.servlet.jsp.jstl-1.2.1.jar


# config https
hostname=`hostname`

systemctl restart crond
echo "0 */1 * * * sh /var/www/html/auditlog/auditlog.sh >/dev/null 2>&1" >> /var/spool/cron/root

\cp -f /opt/inst/idp3config/ssl.conf /etc/httpd/conf.d/ssl.conf
\cp -f /opt/inst/idp3config/idp.conf /etc/httpd/conf.d/idp.conf


# replace secret for apache and tomcat
passwd=`openssl rand 32 -base64`
sed -i "s/xxxxxxxxxxxx/$passwd/g" /etc/tomcat/server.xml
sed -i "s/xxxxxxxxxxxx/$passwd/g" /etc/httpd/conf.d/idp.conf

#copy temporary credentials
mkdir /opt/credentials
\cp -f /opt/inst/idp3config/localhost.crt /opt/credentials/localhost.crt
\cp -f /opt/inst/idp3config/localhost.key /opt/credentials/localhost.key

# config idp
rm -rf /opt/inst/idp3config/shibboleth-identity-provider-3.4.6/
cd /opt/inst/idp3config/
tar xzf shibboleth-identity-provider-3.4.6.tar.gz
sh /opt/inst/idp3config/shibboleth-identity-provider-3.4.6/bin/install.sh
openssl pkcs12 -in /opt/shibboleth-idp/credentials/idp-backchannel.p12 -out /opt/shibboleth-idp/credentials/idp-backchannel.key -nocerts -nodes
\cp -f /opt/inst/idp3config/metadata-providers-pre.xml /opt/shibboleth-idp/conf/metadata-providers.xml
\cp -f /opt/inst/idp3config/attribute-resolver.xml /opt/shibboleth-idp/conf/attribute-resolver.xml
\cp -f /opt/inst/idp3config/no-conversation-state.jsp /opt/shibboleth-idp/edit-webapp/no-conversation-state.jsp
\cp -f /opt/inst/idp3config/shib-cas-authenticator-3.3.0.jar /opt/shibboleth-idp/edit-webapp/WEB-INF/lib/shib-cas-authenticator-3.3.0.jar
\cp -f /opt/inst/idp3config/cas-client-core-3.6.0.jar /opt/shibboleth-idp/edit-webapp/WEB-INF/lib/cas-client-core-3.6.0.jar
\cp -f /opt/inst/idp3config/web.xml /opt/shibboleth-idp/edit-webapp/WEB-INF/web.xml
salt=`openssl rand 32 -base64`
sed -i "s/xxxxxxxxxxxxxxxxxxxx/$salt/g" /opt/shibboleth-idp/conf/attribute-resolver.xml
\cp -f /opt/inst/idp3config/audit.xml /opt/shibboleth-idp/conf/audit.xml
\cp -f /opt/inst/idp3config/consent-intercept-config.xml /opt/shibboleth-idp/conf/intercept/consent-intercept-config.xml
\cp -f /opt/inst/idp3config/relying-party.xml /opt/shibboleth-idp/conf/relying-party.xml
\cp -f /opt/inst/idp3config/attribute-filter.xml /opt/shibboleth-idp/conf/attribute-filter.xml
\cp -f /opt/inst/idp3config/dsmeta.pem /opt/shibboleth-idp/credentials/
sed -i "s/#idp.consent.allowPerAttribute = false/idp.consent.allowPerAttribute = true/g" /opt/shibboleth-idp/conf/idp.properties
wget -P /opt/shibboleth-idp/metadata/ https://dspre.carsi.edu.cn/carsifed-metadata-pre.xml
chown -R tomcat.tomcat /opt/shibboleth-idp
systemctl restart httpd
systemctl restart tomcat
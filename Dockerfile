# Use the official Tomcat 9 base image
FROM tomcat:9

# Remove existing Tomcat application files
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the .war file to the Tomcat webapps directory
COPY target/webapp.war /usr/local/tomcat/webapps/webapp.war

# Start Tomcat when the container launches
CMD ["catalina.sh", "run"]

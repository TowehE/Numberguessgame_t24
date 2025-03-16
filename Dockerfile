FROM tomcat:9-jdk11

COPY target/NumberGuessGame.war /usr/local/tomcat/webapps/
EXPOSE 8080

CMD ["catalina.sh", "run"]

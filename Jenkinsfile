pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        SONAR_SERVER = 'SonarQube'
    }
    
    stages {
        stage('Build Dev Branch') {
            steps {
                echo "Starting build flow with Dev branch"
                checkout([$class: 'GitSCM', branches: [[name: '*/dev']], 
                          userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.CONTEXT_PATH = pom.artifactId.toLowerCase()
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
                
                withSonarQubeEnv(SONAR_SERVER) {
                    sh """
                    mvn sonar:sonar \
                      -Dsonar.projectKey=${env.APP_NAME} \
                      -Dsonar.projectName='${env.APP_NAME}' \
                      -Dsonar.branch.name=dev
                    """
                }
                
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
                
                sh """
                    docker stop numbergame-dev || true
                    docker rm numbergame-dev || true
                    docker run -d -p 8081:8080 --name numbergame-dev \
                        -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/${CONTEXT_PATH}.war \
                        tomcat:9-jre8
                """
                
                sh "sleep 30"
                sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:8081/${CONTEXT_PATH}/ || echo 'Application may still be deploying'"
            }
        }
        
        stage('Build Feature Branch') {
            steps {
                echo "Dev branch successful, continuing with Feature branch"
                checkout([$class: 'GitSCM', branches: [[name: '*/feature']], 
                         userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.CONTEXT_PATH = pom.artifactId.toLowerCase()
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
                
                withSonarQubeEnv(SONAR_SERVER) {
                    sh """
                    mvn sonar:sonar \
                      -Dsonar.projectKey=${env.APP_NAME} \
                      -Dsonar.projectName='${env.APP_NAME}' \
                      -Dsonar.branch.name=feature
                    """
                }
                
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
                
                sh """
                    docker stop numbergame-feature || true
                    docker rm numbergame-feature || true
                    docker run -d -p 8082:8080 --name numbergame-feature \
                        -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/${CONTEXT_PATH}.war \
                        tomcat:9-jre8
                """
                
                sh "sleep 30"
                sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:8082/${CONTEXT_PATH}/ || echo 'Application may still be deploying'"
            }
        }
        
        stage('Build Main Branch') {
            steps {
                echo "Feature branch successful, continuing with Main branch (Production)"
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], 
                         userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.CONTEXT_PATH = pom.artifactId.toLowerCase()
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
                
                withSonarQubeEnv(SONAR_SERVER) {
                    sh """
                    mvn sonar:sonar \
                      -Dsonar.projectKey=${env.APP_NAME} \
                      -Dsonar.projectName='${env.APP_NAME}' \
                      -Dsonar.branch.name=main
                    """
                }
                
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
                
                sh """
                    docker stop numbergame-prod || true
                    docker rm numbergame-prod || true
                    docker run -d -p 8083:8080 --name numbergame-prod \
                        -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/${CONTEXT_PATH}.war \
                        tomcat:9-jre8
                """
                
                sh "sleep 30"
                sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:8083/${CONTEXT_PATH}/ || echo 'Application may still be deploying'"
            }
        }
    }
    
    post {
        success {
            echo "Complete pipeline executed successfully! All branches built and deployed."
        }
        failure {
            echo "Pipeline failed! Check the logs for details."
        }
        always {
            cleanWs()
        }
    }
}

pipeline {
    agent any

    triggers {
        githubPush()  
    }
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        TOMCAT_HOST = 'localhost'
        TOMCAT_PORT = '8080'
        TOMCAT_CREDS = credentials('tomcat-deployer')
        TOMCAT_WEBAPPS = '/home/ec2-user/apache-tomcat-7.0.94/webapps'
        EMAIL_RECIPIENT = 'toweh05@gmail.com'
        SONAR_TOKEN = credentials('sonarqube-token')
        MAVEN_OPTS = "--add-opens java.base/java.lang=ALL-UNNAMED"
    }
    
    stages {
        stage('Build Dev Branch') {
            steps {
                echo "Starting build flow with Dev branch"
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/dev']], 
                          userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                ])
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.DEV_CONTEXT_PATH = "${pom.artifactId}-dev"
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('SonarQube Analysis - Dev') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=${APP_NAME}-dev \
                    -Dsonar.projectName="${APP_NAME} Dev Branch" \
                    -Dsonar.host.url=http://54.92.213.222:9000 \
                    -Dsonar.login=${SONAR_TOKEN} \
                    -Djava.awt.headless=true
                    '''
                }
            }
        }
        
        stage('Deploy Dev') {
            steps {
                script {
                    echo "Deploying Dev branch to Tomcat"
                    
                    // Using Tomcat Manager REST API to deploy
                    sh """
                    curl -v -u ${TOMCAT_CREDS_USR}:${TOMCAT_CREDS_PSW} \
                    -T target/${WAR_FILE} \
                    "http://${TOMCAT_HOST}:${TOMCAT_PORT}/manager/text/deploy?path=/${DEV_CONTEXT_PATH}&update=true"
                    """
                    
                    echo "Dev application deployed at: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${DEV_CONTEXT_PATH}/"
                    sh "sleep 10"
                    sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://${TOMCAT_HOST}:${TOMCAT_PORT}/${DEV_CONTEXT_PATH}/ || echo 'Application may still be deploying'"
                }
            }
        }
        
        stage('Build Feature Branch') {
            steps {
                echo "Dev branch successful, continuing with Feature branch"
                checkout([$class: 'GitSCM', 
                         branches: [[name: '*/feature']], 
                         userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                ])
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.FEATURE_CONTEXT_PATH = "${pom.artifactId}-feature"
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('SonarQube Analysis - Feature') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=${APP_NAME}-feature \
                    -Dsonar.projectName="${APP_NAME} Feature Branch" \
                    -Dsonar.host.url=http://54.92.218.160:9000 \
                    -Dsonar.login=${SONAR_TOKEN} \
                    -Djava.awt.headless=true
                    '''
                }
            }
        }
        
        stage('Deploy Feature') {
            steps {
                script {
                    echo "Deploying Feature branch to Tomcat"
                    
                    // Using Tomcat Manager REST API to deploy
                    sh """
                    curl -v -u ${TOMCAT_CREDS_USR}:${TOMCAT_CREDS_PSW} \
                    -T target/${WAR_FILE} \
                    "http://${TOMCAT_HOST}:${TOMCAT_PORT}/manager/text/deploy?path=/${FEATURE_CONTEXT_PATH}&update=true"
                    """
                    
                    echo "Feature application deployed at: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${FEATURE_CONTEXT_PATH}/"
                    sh "sleep 10"
                    sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://${TOMCAT_HOST}:${TOMCAT_PORT}/${FEATURE_CONTEXT_PATH}/ || echo 'Application may still be deploying'"
                }
            }
        }
        
        stage('Build Main Branch') {
            steps {
                echo "Feature branch successful, continuing with Main branch (Production)"
                checkout([$class: 'GitSCM', 
                         branches: [[name: '*/main']], 
                         userRemoteConfigs: [[url: 'https://github.com/TowehE/Numberguessgame_t24.git']]
                ])
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.PROD_CONTEXT_PATH = pom.artifactId // Production uses the base name
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('SonarQube Analysis - Main') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=${APP_NAME} \
                    -Dsonar.projectName="${APP_NAME} Main Branch" \
                    -Dsonar.host.url=http://54.92.218.160:9000 \
                    -Dsonar.login=${SONAR_TOKEN} \
                    -Djava.awt.headless=true
                    '''
                }
            }
        }
        
        stage('Deploy Main') {
            steps {
                script {
                    echo "Deploying Main branch to Tomcat"
                    
                    // Using Tomcat Manager REST API to deploy
                    sh """
                    curl -v -u ${TOMCAT_CREDS_USR}:${TOMCAT_CREDS_PSW} \
                    -T target/${WAR_FILE} \
                    "http://${TOMCAT_HOST}:${TOMCAT_PORT}/manager/text/deploy?path=/${PROD_CONTEXT_PATH}&update=true"
                    """
                    
                    echo "Production application deployed at: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${PROD_CONTEXT_PATH}/"
                    sh "sleep 10"
                    sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://${TOMCAT_HOST}:${TOMCAT_PORT}/${PROD_CONTEXT_PATH}/ || echo 'Application may still be deploying'"
                }
            }
        }
    }
    
    post {
        success {
            echo "Complete pipeline executed successfully! All branches built and deployed."
            echo "Dev URL: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${DEV_CONTEXT_PATH}/"
            echo "Feature URL: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${FEATURE_CONTEXT_PATH}/"
            echo "Production URL: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${PROD_CONTEXT_PATH}/"
            
            emailext (
                subject: "SUCCESS: Jenkins Pipeline '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>Build Status: SUCCESS</p>
                <p>Job Name: ${env.JOB_NAME}</p>
                <p>Build Number: ${env.BUILD_NUMBER}</p>
                <p>Build URL: ${env.BUILD_URL}</p>
                <p>Deployment URLs:</p>
                <ul>
                    <li>Dev: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${DEV_CONTEXT_PATH}/</li>
                    <li>Feature: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${FEATURE_CONTEXT_PATH}/</li>
                    <li>Production: http://${TOMCAT_HOST}:${TOMCAT_PORT}/${PROD_CONTEXT_PATH}/</li>
                </ul>
                <p>SonarQube Analysis: http://54.92.218.160:9000/dashboard?id=${APP_NAME}</p>""",
                to: "${EMAIL_RECIPIENT}",
                mimeType: 'text/html'
            )
        }
        failure {
            echo "Pipeline failed! Check the logs for details."
            
            emailext (
                subject: "FAILED: Jenkins Pipeline '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>Build Status: FAILED</p>
                <p>Job Name: ${env.JOB_NAME}</p>
                <p>Build Number: ${env.BUILD_NUMBER}</p>
                <p>Build URL: ${env.BUILD_URL}</p>
                <p>Check console output for detailed information about the failure.</p>""",
                to: "${EMAIL_RECIPIENT}",
                mimeType: 'text/html'
            )
        }
        always {
            cleanWs()
        }
    }
}

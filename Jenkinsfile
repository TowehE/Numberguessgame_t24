pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        TOMCAT_HOST = 'localhost'
        TOMCAT_PORT = '8080'
        TOMCAT_CREDS = credentials('tomcat-deployer')
        TOMCAT_WEBAPPS = '/home/ec2-user/apache-tomcat-7.0.94/webapps'  // Updated path
        EMAIL_RECIPIENT = 'toweh02@gmail.com'
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
        
        stage('Deploy Dev') {
            steps {
                script {
                    // Create a deployment script
                    writeFile file: 'deploy_dev.sh', text: """#!/bin/bash
                    # Create temporary directory
                    mkdir -p /tmp/deploy
                    
                    # Copy WAR file to temp directory
                    cp target/${WAR_FILE} /tmp/deploy/${DEV_CONTEXT_PATH}.war
                    
                    # Try to copy directly first
                    if [ -w "${TOMCAT_WEBAPPS}" ]; then
                        cp /tmp/deploy/${DEV_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        echo "Direct copy successful"
                    else
                        # If direct copy fails, try using sudo
                        sudo cp /tmp/deploy/${DEV_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${DEV_CONTEXT_PATH}.war
                        echo "Used sudo to copy"
                    fi
                    """
                    
                    // Make script executable
                    sh 'chmod +x deploy_dev.sh'
                    
                    // Execute deployment script
                    sh './deploy_dev.sh'
                    
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
        
        stage('Deploy Feature') {
            steps {
                script {
                    // Create a deployment script
                    writeFile file: 'deploy_feature.sh', text: """#!/bin/bash
                    # Create temporary directory
                    mkdir -p /tmp/deploy
                    
                    # Copy WAR file to temp directory
                    cp target/${WAR_FILE} /tmp/deploy/${FEATURE_CONTEXT_PATH}.war
                    
                    # Try to copy directly first
                    if [ -w "${TOMCAT_WEBAPPS}" ]; then
                        cp /tmp/deploy/${FEATURE_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        echo "Direct copy successful"
                    else
                        # If direct copy fails, try using sudo
                        sudo cp /tmp/deploy/${FEATURE_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${FEATURE_CONTEXT_PATH}.war
                        echo "Used sudo to copy"
                    fi
                    """
                    
                    // Make script executable
                    sh 'chmod +x deploy_feature.sh'
                    
                    // Execute deployment script
                    sh './deploy_feature.sh'
                    
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
        
        stage('Deploy Main') {
            steps {
                script {
                    // Create a deployment script
                    writeFile file: 'deploy_main.sh', text: """#!/bin/bash
                    # Create temporary directory
                    mkdir -p /tmp/deploy
                    
                    # Copy WAR file to temp directory
                    cp target/${WAR_FILE} /tmp/deploy/${PROD_CONTEXT_PATH}.war
                    
                    # Try to copy directly first
                    if [ -w "${TOMCAT_WEBAPPS}" ]; then
                        cp /tmp/deploy/${PROD_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        echo "Direct copy successful"
                    else
                        # If direct copy fails, try using sudo
                        sudo cp /tmp/deploy/${PROD_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/
                        sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${PROD_CONTEXT_PATH}.war
                        echo "Used sudo to copy"
                    fi
                    """
                    
                    // Make script executable
                    sh 'chmod +x deploy_main.sh'
                    
                    // Execute deployment script
                    sh './deploy_main.sh'
                    
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
                </ul>""",
                to: "${EMAIL_RECIPIENT}",
                mimeType: 'text/html',
                  debug: true 
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
                mimeType: 'text/html',
                  debug: true 
            )
        }
        always {
            cleanWs()
            sh "rm -rf /tmp/deploy || true"
        }
    }
}

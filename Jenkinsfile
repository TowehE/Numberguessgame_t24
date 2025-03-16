pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        TOMCAT_HOST = 'localhost'
        TOMCAT_PORT = '8080'
        TOMCAT_USER = 'ec2-user'
        TOMCAT_SERVER_CREDS = credentials('tomcat-server-ssh')
        TOMCAT_WEBAPPS = '/home/ec2-user/tomcat/webapps'
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
                    env.DEV_CONTEXT_PATH = "${pom.artifactId.toLowerCase()}-dev"
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('Deploy Dev') {
            steps {
                script {
                    // Store the WAR file temporarily
                    sh "mkdir -p /tmp/deployments"
                    sh "cp target/${WAR_FILE} /tmp/deployments/${DEV_CONTEXT_PATH}.war"
                    
                    // Use SSH to deploy with proper permissions
                    sshagent(['tomcat-server-ssh']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_HOST} "sudo mkdir -p ${TOMCAT_WEBAPPS}"
                            scp -o StrictHostKeyChecking=no /tmp/deployments/${DEV_CONTEXT_PATH}.war ${TOMCAT_USER}@${TOMCAT_HOST}:/tmp/
                            ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_HOST} "sudo cp /tmp/${DEV_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/ && sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${DEV_CONTEXT_PATH}.war"
                        """
                    }
                    
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
                    env.FEATURE_CONTEXT_PATH = "${pom.artifactId.toLowerCase()}-feature"
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('Deploy Feature') {
            steps {
                script {
                    // Store the WAR file temporarily
                    sh "mkdir -p /tmp/deployments"
                    sh "cp target/${WAR_FILE} /tmp/deployments/${FEATURE_CONTEXT_PATH}.war"
                    
                    // Use SSH to deploy with proper permissions
                    sshagent(['tomcat-server-ssh']) {
                        sh """
                            scp -o StrictHostKeyChecking=no /tmp/deployments/${FEATURE_CONTEXT_PATH}.war ${TOMCAT_USER}@${TOMCAT_HOST}:/tmp/
                            ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_HOST} "sudo cp /tmp/${FEATURE_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/ && sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${FEATURE_CONTEXT_PATH}.war"
                        """
                    }
                    
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
                    env.PROD_CONTEXT_PATH = pom.artifactId.toLowerCase()  // Production uses the base name
                }
                
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        
        stage('Deploy Main') {
            steps {
                script {
                    // Store the WAR file temporarily
                    sh "mkdir -p /tmp/deployments"
                    sh "cp target/${WAR_FILE} /tmp/deployments/${PROD_CONTEXT_PATH}.war"
                    
                    // Use SSH to deploy with proper permissions
                    sshagent(['tomcat-server-ssh']) {
                        sh """
                            scp -o StrictHostKeyChecking=no /tmp/deployments/${PROD_CONTEXT_PATH}.war ${TOMCAT_USER}@${TOMCAT_HOST}:/tmp/
                            ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_HOST} "sudo cp /tmp/${PROD_CONTEXT_PATH}.war ${TOMCAT_WEBAPPS}/ && sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/${PROD_CONTEXT_PATH}.war"
                        """
                    }
                    
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
        }
        failure {
            echo "Pipeline failed! Check the logs for details."
        }
        always {
            cleanWs()
            sh "rm -rf /tmp/deployments || true"
        }
    }
}

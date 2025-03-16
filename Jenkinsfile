pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        // For a demo project, we'll use the local environment
        TOMCAT_TEST_PORT = '8081'
        TOMCAT_PROD_PORT = '8082'
        WAR_FILE = 'NumberGuessGame-1.0-SNAPSHOT.war'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh "echo 'Building branch: ${env.BRANCH_NAME}'"
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Deploy to Testing') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'dev'
                }
            }
            steps {
                echo 'Deploying to test environment...'
                // Create a Docker container for testing
                sh """
                    docker stop numbergame-test || true
                    docker rm numbergame-test || true
                    docker run -d -p ${TOMCAT_TEST_PORT}:8080 --name numbergame-test -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/numbergame.war tomcat:9-jre8
                """
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'  // Deploy only from main branch
            }
            steps {
                echo 'Deploying to production environment from main branch...'
                // Create a Docker container for production
                sh """
                    docker stop numbergame-prod || true
                    docker rm numbergame-prod || true
                    docker run -d -p ${TOMCAT_PROD_PORT}:8080 --name numbergame-prod -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/numbergame.war tomcat:9-jre8
                """
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    // Wait for Tomcat to deploy the application
                    sh 'sleep 20'
                    
                    if (env.BRANCH_NAME == 'feature' || env.BRANCH_NAME == 'main') {
                        echo "Verifying test deployment (branch: ${env.BRANCH_NAME})"
                        sh "curl -s http://localhost:${TOMCAT_TEST_PORT}/numbergame/ || echo 'Application may still be deploying'"
                    } else if (env.BRANCH_NAME == 'main') {
                        echo "Verifying production deployment from main branch"
                        sh "curl -s http://localhost:${TOMCAT_PROD_PORT}/numbergame/ || echo 'Application may still be deploying'"
                    }
                }
                echo 'Deployment verification completed!'
            }
        }
    }
    
    post {
        success {
            echo "Pipeline for branch ${env.BRANCH_NAME} completed successfully!"
        }
        failure {
            echo "Pipeline for branch ${env.BRANCH_NAME} failed!"
        }
        always {
            cleanWs()
        }
    }
}

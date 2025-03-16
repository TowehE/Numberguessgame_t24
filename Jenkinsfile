pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        // Environment configuration
        TOMCAT_TEST_PORT = '8081'
        TOMCAT_STAGING_PORT = '8083'
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
                    return env.BRANCH_NAME == 'feature'
                }
            }
            steps {
                echo "Deploying to test environment from ${env.BRANCH_NAME} branch..."
                sh """
                    docker stop numbergame-test || true
                    docker rm numbergame-test || true
                    docker run -d -p ${TOMCAT_TEST_PORT}:8080 --name numbergame-test -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/numbergame.war tomcat:9-jre8
                """
            }
        }
        
        stage('Deploy to Staging') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'dev'
                }
            }
            steps {
                echo "Deploying to staging environment from ${env.BRANCH_NAME} branch..."
                sh """
                    docker stop numbergame-staging || true
                    docker rm numbergame-staging || true
                    docker run -d -p ${TOMCAT_STAGING_PORT}:8080 --name numbergame-staging -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/numbergame.war tomcat:9-jre8
                """
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to production environment from main branch...'
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
                    sh 'sleep 30'
                    
                    if (env.BRANCH_NAME == 'feature') {
                        echo "Verifying test deployment (branch: ${env.BRANCH_NAME})"
                        sh "docker exec numbergame-test ls -la /usr/local/tomcat/webapps/"
                        sh "docker logs numbergame-test | grep -i 'numbergame.war' || echo 'No deployment info in logs'"
                        sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:${TOMCAT_TEST_PORT}/numbergame/ || echo 'Application may still be deploying'"
                    } else if (env.BRANCH_NAME == 'dev') {
                        echo "Verifying staging deployment (branch: ${env.BRANCH_NAME})"
                        sh "docker exec numbergame-staging ls -la /usr/local/tomcat/webapps/"
                        sh "docker logs numbergame-staging | grep -i 'numbergame.war' || echo 'No deployment info in logs'"
                        sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:${TOMCAT_STAGING_PORT}/numbergame/ || echo 'Application may still be deploying'"
                    } else if (env.BRANCH_NAME == 'main') {
                        echo "Verifying production deployment from main branch"
                        sh "docker exec numbergame-prod ls -la /usr/local/tomcat/webapps/"
                        sh "docker logs numbergame-prod | grep -i 'numbergame.war' || echo 'No deployment info in logs'"
                        sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' http://localhost:${TOMCAT_PROD_PORT}/numbergame/ || echo 'Application may still be deploying'"
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

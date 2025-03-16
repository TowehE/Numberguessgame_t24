pipeline {
    agent any
    
    tools {
        maven 'Maven'
        jdk 'JDK8'
    }
    
    environment {
        // Automatically detect which branch triggered the build
        BRANCH_NAME = "${env.GIT_BRANCH.replaceAll('origin/', '')}"
        
        // Set port based on branch name
        DEPLOY_PORT = "${BRANCH_NAME == 'dev' ? '8081' : 
                        BRANCH_NAME == 'feature' ? '8082' : 
                        BRANCH_NAME == 'main' ? '8083' : '8080'}"
        
        // Set environment type
        ENV_TYPE = "${BRANCH_NAME == 'main' ? 'production' : 'testing'}"
        
        // SonarQube configuration
        SONAR_SERVER = 'SonarQube'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh "echo 'Building branch: ${BRANCH_NAME}'"
                sh "echo 'Deployment port: ${DEPLOY_PORT}'"
                
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.APP_NAME = pom.artifactId
                    env.APP_VERSION = pom.version
                    env.WAR_FILE = "${pom.artifactId}-${pom.version}.war"
                    env.CONTEXT_PATH = pom.artifactId.toLowerCase()
                }
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
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(SONAR_SERVER) {
                    sh """
                    mvn sonar:sonar \
                      -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                      -Dsonar.projectName='${APP_NAME}' \
                      -Dsonar.sources=src/main \
                      -Dsonar.tests=src/test \
                      -Dsonar.java.binaries=target/classes \
                      -Dsonar.java.test.binaries=target/test-classes \
                      -Dsonar.java.surefire.report=target/surefire-reports \
                      -Dsonar.branch.name=${BRANCH_NAME}
                    """
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    def containerName = "numbergame-${BRANCH_NAME}"
                    
                    echo "Deploying to ${ENV_TYPE} environment from ${BRANCH_NAME} branch on port ${DEPLOY_PORT}..."
                    
                    sh """
                        docker stop ${containerName} || true
                        docker rm ${containerName} || true
                        docker run -d -p ${DEPLOY_PORT}:8080 --name ${containerName} \
                            -v \${WORKSPACE}/target/${WAR_FILE}:/usr/local/tomcat/webapps/${CONTEXT_PATH}.war \
                            tomcat:9-jre8
                    """
                    
                    // Store deployment information
                    writeFile file: "deploy-info-${BRANCH_NAME}.txt", text: """
                        Branch: ${BRANCH_NAME}
                        Environment: ${ENV_TYPE}
                        Container: ${containerName}
                        Port: ${DEPLOY_PORT}
                        Context Path: ${CONTEXT_PATH}
                        Deploy URL: http://localhost:${DEPLOY_PORT}/${CONTEXT_PATH}/
                        Deployment Time: ${new Date()}
                    """
                    
                    archiveArtifacts artifacts: "deploy-info-${BRANCH_NAME}.txt", fingerprint: true
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    def containerName = "numbergame-${BRANCH_NAME}"
                    def deployUrl = "http://localhost:${DEPLOY_PORT}/${CONTEXT_PATH}/"
                    
                    // Wait for Tomcat to deploy the application
                    echo "Waiting ${params.DEPLOY_TIMEOUT} seconds for deployment to complete..."
                    sh "sleep ${params.DEPLOY_TIMEOUT}"
                    
                    echo "Verifying deployment for branch: ${BRANCH_NAME}"
                    
                    // Check if the WAR file was properly deployed
                    sh "docker exec ${containerName} ls -la /usr/local/tomcat/webapps/"
                    
                    // Check Tomcat logs for deployment information
                    sh "docker logs ${containerName} | grep -i '${CONTEXT_PATH}.war' || echo 'No deployment info in logs'"
                    
                    // Check if the application is responding
                    sh "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\\n' ${deployUrl} || echo 'Application may still be deploying'"
                }
            }
        }
        
        stage('Promote to Production') {
            when {
                expression { 
                    return BRANCH_NAME == 'main' 
                }
            }
            steps {
                echo "Main branch detected. This is a production deployment!"
                
                // Add any additional production deployment steps here
                // For example, you might want to:
                // 1. Tag the Docker image for production
                // 2. Update load balancer configuration
                // 3. Send notifications to stakeholders
                
                sh """
                    echo "Production deployment of version ${APP_VERSION} completed on \$(date)" > production-deploy-${APP_VERSION}.log
                """
                
                archiveArtifacts artifacts: "production-deploy-${APP_VERSION}.log", fingerprint: true
            }
        }
    }
    
    post {
        success {
            echo "Pipeline for branch ${BRANCH_NAME} completed successfully!"
        }
        failure {
            echo "Pipeline for branch ${BRANCH_NAME} failed!"
            
            // You could add notification steps here
            // For example, sending emails or Slack messages
        }
        always {
            cleanWs()
        }
    }
}

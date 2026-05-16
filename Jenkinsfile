@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'Node20'
    }

    environment {
        SCANNER_HOME = tool 'Sonar'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                credentialsId: 'Github-token',
                url: 'https://github.com/Suchitdev/Wanderlust.git'
            }
        }

        stage('Install Backend Dependencies') {
            steps {
                dir('backend') {
                    sh 'npm install'
                }
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./',
                odcInstallation: 'OWASP'
            }
        }

        stage('OWASP Publish Report') {
            steps {
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=Wanderlust \
                    -Dsonar.projectKey=Wanderlust \
                    -Dsonar.sources=backend,frontend/src \
                    -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/.next/**,**/coverage/**
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Docker Build Backend') {
            steps {
                script {
                    docker.build(
                        "suchit10/wanderlust-backend:latest",
                        "./backend"
                    )
                }
            }
        }

        stage('Docker Build Frontend') {
            steps {
                script {
                    docker.build(
                        "suchit10/wanderlust-frontend:latest",
                        "./frontend"
                    )
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'DockerHub Credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Docker Push Backend') {
            steps {
                sh 'docker push suchit10/wanderlust-backend:latest'
            }
        }

        stage('Docker Push Frontend') {
            steps {
                sh 'docker push suchit10/wanderlust-frontend:latest'
            }
        }

    }

    post {

        always {
            echo 'Pipeline Completed'
        }

        success {
            echo 'CI Pipeline Passed!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }
    }
}
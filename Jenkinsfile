@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'node16'
    }

    environment {
        SONAR_HOME = tool 'Sonar'
    }

    stages {

        stage('Git Checkout') {
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

        stage('Trivy Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./',
                odcInstallation: 'DP-Check'
            }
        }

        stage('Publish OWASP Report') {
            steps {
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                    $SONAR_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Wanderlust \
                    -Dsonar.projectKey=Wanderlust
                    '''
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
                dir('backend') {
                    sh 'docker build -t suchit10/wanderlust-backend:latest .'
                }
            }
        }

        stage('Docker Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'docker build -t suchit10/wanderlust-frontend:latest .'
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHub Credentials',
                    passwordVariable: 'DOCKER_PASS',
                    usernameVariable: 'DOCKER_USER'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
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
            echo 'CI Pipeline Success!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }
    }
}
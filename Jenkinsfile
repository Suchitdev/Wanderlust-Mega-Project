@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'Node20'
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'
    }

    parameters {

        string(
            name: 'FRONTEND_DOCKER_TAG',
            defaultValue: 'v1',
            description: 'Frontend Docker Image Tag'
        )

        string(
            name: 'BACKEND_DOCKER_TAG',
            defaultValue: 'v1',
            description: 'Backend Docker Image Tag'
        )
    }

    stages {

        stage('Validate Parameters') {
            steps {
                script {
                    if (
                        params.FRONTEND_DOCKER_TAG.trim() == "" ||
                        params.BACKEND_DOCKER_TAG.trim() == ""
                    ) {
                        error("Docker tags are required")
                    }
                }
            }
        }

        stage('Git: Code Checkout') {
            steps {
                git branch: 'main',
                credentialsId: 'Github-token',
                url: 'https://github.com/Suchitdev/Wanderlust-Mega-Project.git'
            }
        }

        stage('Install Backend Dependencies') {
            steps {
                dir('backend') {
                    sh '''
                        npm install --legacy-peer-deps
                    '''
                }
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                dir('frontend') {
                    sh '''
                        npm install --legacy-peer-deps
                    '''
                }
            }
        }

        stage('Trivy: Filesystem Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('OWASP: Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./',
                odcInstallation: 'OWASP'
            }
        }

        stage('OWASP: Publish Report') {
            steps {
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('SonarQube: Code Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=Wanderlust \
                        -Dsonar.projectKey=Wanderlust \
                        -Dsonar.sources=backend,frontend/src \
                        -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/.next/**,**/coverage/** \
                        -Dsonar.javascript.node.maxspace=4096
                        """
                    }
                }
            }
        }

        stage('SonarQube: Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Docker: Build Backend Image') {
            steps {
                dir('backend') {
                    sh """
                        docker build -t suchit10/wanderlust-backend:${params.BACKEND_DOCKER_TAG} .
                    """
                }
            }
        }

        stage('Docker: Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh """
                        docker build -t suchit10/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG} .
                    """
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
                        sh """
                            docker push suchit10/wanderlust-backend:${params.BACKEND_DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Docker: Push Frontend Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
                        sh """
                            docker push suchit10/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Generate Reports') {
            steps {
                echo 'Pipeline Completed Successfully'
            }
        }
    }

    post {

        success {
            echo 'CI Pipeline Success!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }

        always {
            cleanWs()
        }
    }
}
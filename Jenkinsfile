@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'
        NODEJS_HOME = tool 'NodeJS'
        PATH = "${NODEJS_HOME}/bin:${env.PATH}"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'latest', description: 'Frontend Docker Tag')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'latest', description: 'Backend Docker Tag')
    }

    stages {

        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.FRONTEND_DOCKER_TAG || !params.BACKEND_DOCKER_TAG) {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG are required.")
                    }
                }
            }
        }

        stage('Workspace Cleanup') {
            steps {
                cleanWs()
            }
        }

        stage('Git: Code Checkout') {
            steps {
                git branch: 'main',
                credentialsId: 'Github-token',
                url: 'https://github.com/Suchitdev/Wanderlust-Mega-Project.git'
            }
        }

        stage('Environment Setup') {
            parallel {

                stage('Backend Env Setup') {
                    steps {
                        dir('backend') {
                            sh '''
                            node -v
                            npm -v
                            npm install
                            '''
                        }
                    }
                }

                stage('Frontend Env Setup') {
                    steps {
                        dir('frontend') {
                            sh '''
                            node -v
                            npm -v
                            npm install
                            '''
                        }
                    }
                }
            }
        }

        stage('Trivy: Filesystem Scan') {
            steps {
                script {
                    sh 'trivy fs .'
                }
            }
        }

        stage('OWASP: Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./',
                odcInstallation: 'OWASP'
            }
        }

        stage('Publish OWASP Report') {
            steps {
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('SonarQube: Code Analysis') {
            steps {
                withSonarQubeEnv('sonar') {

                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Wanderlust \
                    -Dsonar.projectKey=Wanderlust \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://13.232.119.76:9000 \
                    -Dsonar.login=YOUR_SONAR_TOKEN
                    '''
                }
            }
        }

        stage('SonarQube: Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false
            }
        }

        stage('Docker: Build Backend Image') {
            steps {
                script {
                    dockerbuild(
                        imageName: 'suchitdeshmukh/wanderlust-backend-beta',
                        imageTag: "${params.BACKEND_DOCKER_TAG}",
                        dockerfile: 'backend/Dockerfile',
                        context: './backend'
                    )
                }
            }
        }

        stage('Docker: Build Frontend Image') {
            steps {
                script {
                    dockerbuild(
                        imageName: 'suchitdeshmukh/wanderlust-frontend-beta',
                        imageTag: "${params.FRONTEND_DOCKER_TAG}",
                        dockerfile: 'frontend/Dockerfile',
                        context: './frontend'
                    )
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                script {
                    dockerpush(
                        imageName: 'suchitdeshmukh/wanderlust-backend-beta',
                        imageTag: "${params.BACKEND_DOCKER_TAG}",
                        credentials: 'docker-hub-credentials'
                    )
                }
            }
        }

        stage('Docker: Push Frontend Image') {
            steps {
                script {
                    dockerpush(
                        imageName: 'suchitdeshmukh/wanderlust-frontend-beta',
                        imageTag: "${params.FRONTEND_DOCKER_TAG}",
                        credentials: 'docker-hub-credentials'
                    )
                }
            }
        }

        stage('Generate Reports') {
            steps {
                script {
                    generatereports(
                        projectName: 'Wanderlust',
                        imageName: 'wanderlust-images',
                        imageTag: "${params.BACKEND_DOCKER_TAG}"
                    )
                }
            }
        }
    }

    post {

        success {
            echo 'CI Pipeline Completed Successfully!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }

        always {
            cleanWs()
        }
    }
}
@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
        
    }

    environment {
        SONAR_HOME = tool 'SonarScanner'
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'v1', description: 'Frontend Docker Tag')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'v1', description: 'Backend Docker Tag')
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
                credentialsId: 'Github',
                url: 'https://github.com/Suchitdev/Wanderlust-Mega-Project.git'
            }
        }

        stage('Install Dependencies') {
            parallel {

                stage('Backend Dependencies') {
                    steps {
                        dir('backend') {
                            sh 'npm install'
                        }
                    }
                }

                stage('Frontend Dependencies') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
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
                dependencyCheck additionalArguments: '--scan .',
                odcInstallation: 'OWASP'
            }
        }

        stage('OWASP: Publish Report') {
            steps {
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('SonarQube: Code Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh """
                    \$SONAR_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Wanderlust \
                    -Dsonar.projectKey=Wanderlust \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://13.232.119.76:9000 \
                    -Dsonar.login=YOUR_SONAR_TOKEN
                    """
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
                    dockerbuild(
                        imageName: 'suchitdeshmukh/wanderlust-backend-beta',
                        imageTag: "${params.BACKEND_DOCKER_TAG}"
                    )
                }
            }
        }

        stage('Docker: Build Frontend Image') {
            steps {
                dir('frontend') {
                    dockerbuild(
                        imageName: 'suchitdeshmukh/wanderlust-frontend-beta',
                        imageTag: "${params.FRONTEND_DOCKER_TAG}"
                    )
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                dockerpush(
                    imageName: 'suchitdeshmukh/wanderlust-backend-beta',
                    imageTag: "${params.BACKEND_DOCKER_TAG}",
                    credentials: 'docker-hub-credentials'
                )
            }
        }

        stage('Docker: Push Frontend Image') {
            steps {
                dockerpush(
                    imageName: 'suchitdeshmukh/wanderlust-frontend-beta',
                    imageTag: "${params.FRONTEND_DOCKER_TAG}",
                    credentials: 'docker-hub-credentials'
                )
            }
        }

        stage('Generate Reports') {
            steps {
                generatereports(
                    projectName: 'Wanderlust',
                    imageName: 'wanderlust-images',
                    imageTag: "${params.FRONTEND_DOCKER_TAG}"
                )
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
            script {
                cleanWs()
            }
        }
    }
}
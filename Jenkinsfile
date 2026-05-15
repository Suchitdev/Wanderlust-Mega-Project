@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'
        SONARQUBE_ENV = 'sonar'
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

        stage('Install Backend Dependencies') {
            steps {
                script {
                    dir('backend') {
                        sh '''
                            npm install
                        '''
                    }
                }
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                script {
                    dir('frontend') {
                        sh '''
                            npm install
                        '''
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

        stage('OWASP: Publish Report') {
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
                        -Dsonar.host.url=http://sonarqube:9000 \
                        -Dsonar.login=admin
                    '''
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
                script {
                    dir('backend') {
                        sh """
                            docker build -t suchitdev/wanderlust-backend:${params.BACKEND_DOCKER_TAG} .
                        """
                    }
                }
            }
        }

        stage('Docker: Build Frontend Image') {
            steps {
                script {
                    dir('frontend') {
                        sh """
                            docker build -t suchitdev/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG} .
                        """
                    }
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
                        sh """
                            docker push suchitdev/wanderlust-backend:${params.BACKEND_DOCKER_TAG}
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
                            docker push suchitdev/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Generate Reports') {
            steps {
                echo 'Reports Generated Successfully'
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
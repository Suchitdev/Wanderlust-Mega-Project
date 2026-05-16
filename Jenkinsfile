@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'Node20'
    }

    environment {
        SONAR_HOME = tool 'Sonar'
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'latest', description: 'Frontend Docker tag')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'latest', description: 'Backend Docker tag')
    }

    stages {

        stage('Validate Parameters') {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG.trim() == '') {
                        error("FRONTEND_DOCKER_TAG cannot be empty")
                    }

                    if (params.BACKEND_DOCKER_TAG.trim() == '') {
                        error("BACKEND_DOCKER_TAG cannot be empty")
                    }
                }
            }
        }

        stage('Git: Code Checkout') {
            steps {
                git branch: 'main',
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

        stage('Trivy: Filesystem Scan') {
            steps {
                script {
                    trivy_scan('fs .')
                }
            }
        }

        stage('OWASP: Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '''
                    --scan .
                    --disableYarnAudit
                    --disableNodeAudit
                ''',
                odcInstallation: 'DP-Check'
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
                    sh """
                    ${SONAR_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=Wanderlust \
                    -Dsonar.projectKey=Wanderlust \
                    -Dsonar.sources=backend,frontend/src \
                    -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/.next/**,**/coverage/** \
                    -Dsonar.javascript.node.maxspace=4096
                    """
                }
            }
        }

        stage('SonarQube: Quality Gate') {
            steps {
                echo 'Skipping Quality Gate for low-memory EC2 instance'
            }
        }

        stage('Docker: Build Backend Image') {
            steps {
                dir('backend') {
                    script {
                        docker_build(
                            "suchitdev/wanderlust-backend:${params.BACKEND_DOCKER_TAG}",
                            "."
                        )
                    }
                }
            }
        }

        stage('Docker: Build Frontend Image') {
            steps {
                dir('frontend') {
                    script {
                        docker_build(
                            "suchitdev/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG}",
                            "."
                        )
                    }
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                script {
                    docker_push("suchitdev/wanderlust-backend:${params.BACKEND_DOCKER_TAG}")
                }
            }
        }

        stage('Docker: Push Frontend Image') {
            steps {
                script {
                    docker_push("suchitdev/wanderlust-frontend:${params.FRONTEND_DOCKER_TAG}")
                }
            }
        }

        stage('Generate Reports') {
            steps {
                echo 'Pipeline completed successfully!'
            }
        }
    }

    post {
        success {
            echo 'CI Pipeline Passed!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }

        always {
            cleanWs()
        }
    }
}
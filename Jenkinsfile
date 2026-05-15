@Library('Shared') _

pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'
    }

    parameters {
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'v1', description: 'Backend Docker Tag')
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'v1', description: 'Frontend Docker Tag')
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                credentialsId: 'Github',
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

        stage('Docker: Build Backend Image') {
            steps {
                dir('backend') {
                    script {
                        docker_build(
                            'wanderlust-backend',
                            params.BACKEND_DOCKER_TAG,
                            'suchit10'
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
                            'wanderlust-frontend',
                            params.FRONTEND_DOCKER_TAG,
                            'suchit10'
                        )
                    }
                }
            }
        }

        stage('Docker: Push Backend Image') {
            steps {
                script {
                    docker_push(
                        'wanderlust-backend',
                        params.BACKEND_DOCKER_TAG,
                        'suchit10'
                    )
                }
            }
        }

        stage('Docker: Push Frontend Image') {
            steps {
                script {
                    docker_push(
                        'wanderlust-frontend',
                        params.FRONTEND_DOCKER_TAG,
                        'suchit10'
                    )
                }
            }
        }

        stage('Generate Reports') {
            steps {
                echo 'CI Pipeline Completed Successfully!'
            }
        }
    }

    post {
        always {
            cleanWs()
        }

        success {
            echo 'CI Pipeline Passed!'
        }

        failure {
            echo 'CI Pipeline Failed!'
        }
    }
}
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
        string(
            name: 'FRONTEND_DOCKER_TAG',
            defaultValue: 'latest',
            description: 'Frontend Docker Image Tag'
        )

        string(
            name: 'BACKEND_DOCKER_TAG',
            defaultValue: 'latest',
            description: 'Backend Docker Image Tag'
        )
    }

    stages {

        stage('Git Checkout') {
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
                        npm install
                    '''
                }
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                dir('frontend') {
                    sh '''
                        npm install
                    '''
                }
            }
        }

        stage('Trivy File Scan') {
            steps {
                sh '''
                    trivy fs . --severity HIGH,CRITICAL
                '''
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '''
                        --scan .
                        --disableAssembly
                    ''',
                    odcInstallation: 'OWASP'
                )
            }
        }

        stage('Publish OWASP Report') {
            steps {
                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {

                    sh '''
                        $SONAR_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Wanderlust \
                        -Dsonar.projectKey=Wanderlust \
                        -Dsonar.sources=. \
                        -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    script {

                        def qg = waitForQualityGate()

                        echo "Quality Gate Status: ${qg.status}"

                        if (qg.status != 'OK') {

                            echo 'Quality Gate failed, but pipeline will continue.'

                        } else {

                            echo 'Quality Gate Passed.'

                        }
                    }
                }
            }
        }

        stage('Docker Build Backend') {
            steps {

                dir('backend') {

                    sh """
                        docker build \
                        -t suchit10/wanderlust-backend:${BACKEND_DOCKER_TAG} .
                    """
                }
            }
        }

        stage('Docker Build Frontend') {
            steps {

                dir('frontend') {

                    sh """
                        docker build \
                        -t suchit10/wanderlust-frontend:${FRONTEND_DOCKER_TAG} .
                    """
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
                        echo "$DOCKER_PASS" | docker login \
                        -u "$DOCKER_USER" \
                        --password-stdin
                    '''
                }
            }
        }

        stage('Docker Push Backend') {
            steps {

                sh """
                    docker push suchit10/wanderlust-backend:${BACKEND_DOCKER_TAG}
                """
            }
        }

        stage('Docker Push Frontend') {
            steps {

                sh """
                    docker push suchit10/wanderlust-frontend:${FRONTEND_DOCKER_TAG}
                """
            }
        }
    }

    post {

        always {

            echo 'Pipeline Completed'

            cleanWs()
        }

        success {

            echo 'CI Pipeline Success!'
        }

        failure {

            echo 'CI Pipeline Failed!'
        }
    }
}
@Library('Shared') _

pipeline {

    agent {
        label 'Node'
    }

    environment {
        SONAR_HOME = tool 'Sonar'
    }

    parameters {

        string(
            name: 'FRONTEND_DOCKER_TAG',
            defaultValue: '',
            description: 'Frontend Docker Image Tag'
        )

        string(
            name: 'BACKEND_DOCKER_TAG',
            defaultValue: '',
            description: 'Backend Docker Image Tag'
        )
    }

    stages {

        stage('Validate Parameters') {

            steps {

                script {

                    if (
                        params.FRONTEND_DOCKER_TAG.trim() == '' ||
                        params.BACKEND_DOCKER_TAG.trim() == ''
                    ) {

                        error('FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG are required.')
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
                url: 'https://github.com/Suchitdev/wanderlust-devops.git'
            }
        }

        stage('Trivy: Filesystem Scan') {

            steps {

                script {
                    trivy_scan()
                }
            }
        }

        stage('OWASP: Dependency Check') {

            steps {

                dependencyCheck(
                    additionalArguments: '--scan ./',
                    odcInstallation: 'OWASP'
                )

                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('SonarQube: Code Analysis') {

            steps {

                withSonarQubeEnv('Sonar') {

                    sh """
                        ${SONAR_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=wanderlust \
                        -Dsonar.projectKey=wanderlust \
                        -Dsonar.sources=.
                    """
                }
            }
        }

        stage('SonarQube: Quality Gate') {

            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Environment Setup') {

            parallel {

                stage('Backend Env Setup') {

                    steps {

                        dir('Automations') {

                            sh 'bash updatebackendnew.sh'
                        }
                    }
                }

                stage('Frontend Env Setup') {

                    steps {

                        dir('Automations') {

                            sh 'bash updatefrontendnew.sh'
                        }
                    }
                }
            }
        }

        stage('Docker: Build Images') {

            steps {

                script {

                    dir('backend') {

                        docker_build(
                            'wanderlust-backend-beta',
                            "${params.BACKEND_DOCKER_TAG}",
                            'suchitdev'
                        )
                    }

                    dir('frontend') {

                        docker_build(
                            'wanderlust-frontend-beta',
                            "${params.FRONTEND_DOCKER_TAG}",
                            'suchitdev'
                        )
                    }
                }
            }
        }

        stage('Docker: Push Images') {

            steps {

                script {

                    docker_push(
                        'wanderlust-backend-beta',
                        "${params.BACKEND_DOCKER_TAG}",
                        'suchitdev'
                    )

                    docker_push(
                        'wanderlust-frontend-beta',
                        "${params.FRONTEND_DOCKER_TAG}",
                        'suchitdev'
                    )
                }
            }
        }
    }

    post {

        success {

            archiveArtifacts(
                artifacts: '*.xml',
                followSymlinks: false
            )

            build job: 'Wanderlust-CD',
            parameters: [

                string(
                    name: 'FRONTEND_DOCKER_TAG',
                    value: "${params.FRONTEND_DOCKER_TAG}"
                ),

                string(
                    name: 'BACKEND_DOCKER_TAG',
                    value: "${params.BACKEND_DOCKER_TAG}"
                )
            ]
        }

        failure {

            echo 'CI Pipeline Failed!'
        }

        always {

            cleanWs()
        }
    }
}
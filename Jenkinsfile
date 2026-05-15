@Library('Shared') _

pipeline {

    agent any

    environment {
        SONAR_HOME = tool "Sonar"
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

        stage("Validate Parameters") {
            steps {

                script {

                    if (
                        params.FRONTEND_DOCKER_TAG.trim() == '' ||
                        params.BACKEND_DOCKER_TAG.trim() == ''
                    ) {

                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG are required.")
                    }

                }

            }
        }

        stage("Workspace Cleanup") {
            steps {

                cleanWs()

            }
        }

        stage("Git: Code Checkout") {
            steps {

                git(
                    branch: 'main',
                    credentialsId: 'Github',
                    url: 'https://github.com/Suchitdev/Wanderlust-Mega-Project.git'
                )

            }
        }

        stage("Trivy: Filesystem Scan") {
            steps {

                script {

                    trivy_scan()

                }

            }
        }

        stage("OWASP: Dependency Check") {
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

        stage("SonarQube: Code Analysis") {
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

        stage("SonarQube: Quality Gate") {
            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true

                }

            }
        }

        stage("Environment Setup") {

            parallel {

                stage("Backend Env Setup") {
                    steps {

                        dir("Automations") {

                            sh "bash updatebackendnew.sh"

                        }

                    }
                }

                stage("Frontend Env Setup") {
                    steps {

                        dir("Automations") {

                            sh "bash updatefrontendnew.sh"

                        }

                    }
                }

            }

        }

        stage("Docker: Build Backend Image") {
            steps {

                dir("backend") {

                    docker_build(
                        imageName: "suchitdev/wanderlust-backend-beta",
                        imageTag: "${params.BACKEND_DOCKER_TAG}"
                    )

                }

            }
        }

        stage("Docker: Build Frontend Image") {
            steps {

                dir("frontend") {

                    docker_build(
                        imageName: "suchitdev/wanderlust-frontend-beta",
                        imageTag: "${params.FRONTEND_DOCKER_TAG}"
                    )

                }

            }
        }

        stage("Docker: Push Backend Image") {
            steps {

                docker_push(
                    imageName: "suchitdev/wanderlust-backend-beta",
                    imageTag: "${params.BACKEND_DOCKER_TAG}"
                )

            }
        }

        stage("Docker: Push Frontend Image") {
            steps {

                docker_push(
                    imageName: "suchitdev/wanderlust-frontend-beta",
                    imageTag: "${params.FRONTEND_DOCKER_TAG}"
                )

            }
        }

        stage("Generate Reports") {
            steps {

                generate_reports(
                    projectName: "Wanderlust",
                    imageName: "wanderlust-images",
                    imageTag: "${params.FRONTEND_DOCKER_TAG}"
                )

            }
        }
    }

    post {

        success {

            echo "CI Pipeline Completed Successfully!"

            build job: "Wanderlust-CD",

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

            echo "CI Pipeline Failed!"

        }

        always {

            cleanWs()

        }
    }
}
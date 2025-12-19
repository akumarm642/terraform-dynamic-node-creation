pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.6'
            args '--entrypoint=""'  // ensures we can run shell commands
        }
    }

    environment {
        // Set your AWS credentials stored in Jenkins
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY
                        terraform init -reconfigure
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY
                        terraform plan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            when { branch 'main' }  // only apply on main branch
            steps {
                withCredentials([file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY
                        terraform apply -auto-approve
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
        success {
            echo "Terraform applied successfully!"
        }
        failure {
            echo "Terraform failed"
        }
    }
}


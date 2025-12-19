pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.6'
            args '--entrypoint=""'
        }
    }

    parameters {
        choice(
            name: 'TF_ACTION',
            choices: ['apply', 'destroy'],
            description: 'Terraform action to perform'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'eu-north-1'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')
                ]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY
                        terraform init -reconfigure
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.TF_ACTION == 'apply' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')
                ]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY
                        terraform plan
                    '''
                }
            }
        }

        stage('Terraform Apply / Destroy') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    file(credentialsId: 'ssh-public-key', variable: 'SSH_KEY')
                ]) {
                    sh '''
                        export TF_VAR_public_key_path=$SSH_KEY

                        if [ "${TF_ACTION}" = "apply" ]; then
                          terraform apply -auto-approve
                        else
                          terraform destroy -auto-approve
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Terraform ${TF_ACTION} completed successfully"
        }
        failure {
            echo "Terraform ${TF_ACTION} failed"
        }
        always {
            echo "Pipeline finished"
        }
    }
}


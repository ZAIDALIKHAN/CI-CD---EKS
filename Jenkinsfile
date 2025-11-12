pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '069380454032.dkr.ecr.us-east-1.amazonaws.com/terraform-cicd-app'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        CLUSTER_NAME = 'demo-clusteree'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                git branch: 'main', url: 'https://github.com/ZAIDALIKHAN/CI-CD---EKS.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME .'
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $ECR_REPO
                '''
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                sh '''
                docker tag $IMAGE_NAME:latest $ECR_REPO:$IMAGE_TAG
                docker tag $IMAGE_NAME:latest $ECR_REPO:latest
                docker push $ECR_REPO:$IMAGE_TAG
                docker push $ECR_REPO:latest
                '''
            }
        }


        stage('Verify eksctl') {
            steps {
                sh '''
                echo "=== Checking eksctl binary path and version ==="
                which eksctl || echo "eksctl not found in PATH!"
                /usr/bin/env /usr/local/bin/eksctl version || echo "eksctl failed to run!"
                echo "=== Checking environment ==="
                env | grep AWS || echo "No AWS vars set"
                '''
           }
        }


        stage('Create EKS') {
            steps {
                sh '''
                echo "enetered hereraa pukka"
                /usr/bin/env /usr/local/bin/eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --fargate
                '''
            }
        }
            

    }
                    

    post {
        success {
            echo "✅ ECR Push successful!"
        }
        failure {
            echo "❌ Pipeline failed! Check Jenkins console logs."
        }
        always {
            cleanWs()
        }
    }
}

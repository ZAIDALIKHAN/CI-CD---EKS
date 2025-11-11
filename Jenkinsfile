pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '069380454032.dkr.ecr.us-east-1.amazonaws.com/myapp'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        CLUSTER_NAME = 'demo-cluster'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                git branch: 'main', url: 'https://github.com/ZAIDALIKHAN/Jenkins-CI-CD-Docker-Terraform-Ansible.git'
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
                docker push $ECR_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Configure kubectl') {
            steps {
                sh '''
                echo "Configuring kubectl for EKS..."
                aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                kubectl get nodes
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "Deploying to EKS cluster..."
                    sed -i "s|069380454032.dkr.ecr.us-east-1.amazonaws.com/myapp:.*|069380454032.dkr.ecr.us-east-1.amazonaws.com/myapp:${IMAGE_TAG}|g" k8/deployment.yaml

                    kubectl apply -f k8/deployment.yaml
                    kubectl apply -f k8/service.yaml

                    echo "Waiting for LoadBalancer..."
                    sleep 30
                    kubectl get svc myapp-service
                '''
            }
        }
    }

    post {
        success {
            echo "✅ EKS deployment successful!"
        }
        failure {
            echo "❌ Pipeline failed! Check Jenkins console logs."
        }
        always {
            cleanWs()
        }
    }
}

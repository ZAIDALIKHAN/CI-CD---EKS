pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '069380454032.dkr.ecr.us-east-1.amazonaws.com/terraform-cicd-app'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        CLUSTER_NAME = 'demo-cluster'
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
                docker push $ECR_REPO:$IMAGE_TAG
                '''
            }
        }

        //stage('Create EKS'){
         // steps {
          //    sh '''
           //   ⁠/usr/bin/env /usr/local/bin/eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --fargate
            //  ⁠/usr/local/bin/eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
             //   '''
           // }
        //}
            

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

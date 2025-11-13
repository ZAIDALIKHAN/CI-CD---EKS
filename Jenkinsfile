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


      stage('Create or Verify EKS Cluster') {
            steps {
                script {
                    echo "Checking if EKS cluster '$CLUSTER_NAME' exists..."
                    def clusterExists = sh(
                        script: "eksctl get cluster --region $AWS_REGION | grep -w $CLUSTER_NAME || true",
                        returnStatus: true
                    )

                    if (clusterExists == 0) {
                        echo "Cluster '$CLUSTER_NAME' already exists — skipping creation."
                    } else {
                        echo "Cluster not found — creating a new one..."
                        sh """
                        /usr/bin/env /usr/local/bin/eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --fargate
                        """
                    }
                }

               sh '''
               eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
               aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

               
               if eksctl get fargateprofile --cluster $CLUSTER_NAME --region $AWS_REGION | grep -q 'alb-sample-app'; then
                echo "Fargate profile 'alb-sample-app' already exists. Skipping creation."
               else
                echo "Creating Fargate profile 'alb-sample-app'..."
                eksctl create fargateprofile --cluster $CLUSTER_NAME --region $AWS_REGION --name alb-sample-app --namespace game-2048
               fi

               
               
               '''
            }
        }


        stage('Setup AWS Load Balancer Controller') {
    steps {
        sh '''
        set -e

        echo "=== Step 1: Download IAM Policy for ALB Controller ==="
        if [ ! -f iam_policy.json ]; then
          curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
        else
          echo " iam_policy.json already exists. Skipping download."
        fi


        echo "=== Step 2: Create IAM Policy (if not exists) ==="
        POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID:-069380454032}:policy/AWSLoadBalancerControllerIAMPolicy"
        if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
          echo " IAM Policy already exists. Skipping creation."
        else
          echo "Creating IAM Policy..."
          aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
        fi


        echo "=== Step 3: Create IAM Service Account (if not exists) ==="
        if eksctl get iamserviceaccount --cluster=$CLUSTER_NAME --region=$AWS_REGION -n kube-system | grep -q aws-load-balancer-controller; then
          echo "IAM Service Account already exists. Skipping creation."
        else
          echo " Creating IAM Service Account..."
          eksctl create iamserviceaccount \
            --cluster=$CLUSTER_NAME \
            --namespace=kube-system \
            --name=aws-load-balancer-controller \
            --role-name AmazonEKSLoadBalancerControllerRole \
            --attach-policy-arn=$POLICY_ARN \
            --approve
        fi


        echo "=== Step 4: Add and Update Helm Repo ==="
        if ! helm repo list | grep -q eks; then
          helm repo add eks https://aws.github.io/eks-charts
        else
          echo " Helm repo 'eks' already exists."
        fi
        helm repo update eks


        echo "=== Step 5: Install or Upgrade AWS Load Balancer Controller via Helm ==="
        if helm list -n kube-system | grep -q aws-load-balancer-controller; then
          echo "Helm release already exists. Upgrading..."
          helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
            --set clusterName=$CLUSTER_NAME \
            --set serviceAccount.create=false \
            --set serviceAccount.name=aws-load-balancer-controller \
            --set region=$AWS_REGION \
            --set vpcId=vpc-0b4e0f2a04d59efad
        else
          echo " Installing Helm chart for AWS Load Balancer Controller..."
          helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
            --set clusterName=$CLUSTER_NAME \
            --set serviceAccount.create=false \
            --set serviceAccount.name=aws-load-balancer-controller \
            --set region=$AWS_REGION \
            --set vpcId=vpc-0b4e0f2a04d59efad
        fi


        echo "=== Step 6: Verify Deployment ==="
        kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s || true
        kubectl get deployment -n kube-system aws-load-balancer-controller
        '''
    }
}



    stage('Deploy to EKS') {
    steps {
        script {
            echo "📦 Deploying application to EKS..."

            // Ensure kubeconfig is up to date
            sh '''
                aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
            '''

            // Apply all Kubernetes manifests safely (Deployment, Service, Ingress)
            sh '''
                if [ -f deployment.yaml ]; then
                    kubectl apply -f deployment.yaml || true
                fi

                if [ -f service.yaml ]; then
                    kubectl apply -f service.yaml || true
                fi

                if [ -f ingress.yaml ]; then
                    kubectl apply -f ingress.yaml || true
                fi

                # Wait for rollout to complete (safe even if already up-to-date)
                kubectl rollout status deployment/myapp-deployment -n game-2048 --timeout=180s || true

                echo "✅ Application successfully deployed on EKS via Fargate!"
            '''
        }
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

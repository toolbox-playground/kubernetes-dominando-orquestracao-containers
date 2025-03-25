#!/bin/bash

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "Dependencies installed!"
}

# Function to create the Kubernetes cluster
create_cluster() {
    echo "Creating Kubernetes cluster with K3d..."
    k3d cluster create k8s-lab \
        --servers 1 \
        --agents 2 \
        --port 8095:80@loadbalancer
    echo "Cluster created!"
    kubectl get nodes
}

# Function to deploy the Hello World app
deploy_app() {
    echo "Deploying Hello World application..."
    kubectl apply -f hello-world-deployment.yaml
    kubectl apply -f hello-world-service.yaml
    kubectl create configmap hello-world-app --from-file=app.py
    echo "Application deployed!"
}

# Function to deploy Ingress (optional)
deploy_ingress() {
    echo "Deploying Ingress..."
    kubectl apply -f hello-world-ingress.yaml
    echo "Ingress deployed!"
}

# Function to test the application
test_app() {
    echo "Testing application..."
    kubectl run test --rm -it --image=busybox -- sh -c "wget -qO- http://hello-world-service:5000"
}

# Function to delete the cluster
delete_cluster() {
    echo "Deleting Kubernetes cluster..."
    k3d cluster delete k8s-lab
    echo "Cluster deleted!"
}

# Function to show the menu
show_menu() {
    while true; do
        echo "\nSelect an option:"
        echo "1) Install dependencies"
        echo "2) Create Kubernetes cluster"
        echo "3) Deploy Hello World app"
        echo "4) Deploy Ingress"
        echo "5) Test application"
        echo "6) Delete cluster"
        echo "7) Exit"
        read -p "Enter your choice: " choice

        case $choice in
            1) install_dependencies ;;
            2) create_cluster ;;
            3) deploy_app ;;
            4) deploy_ingress ;;
            5) test_app ;;
            6) delete_cluster ;;
            7) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

# Run the menu
show_menu

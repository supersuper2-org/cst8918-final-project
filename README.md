# CST8918 Final Project

## IaC and Github CI/CD with Remix Weather App

## Team Members
- Simar Singh (sing1883) [GitHub Profile](https://github.com/supersuper2)
- Abdulrafay Mohammed (abdulRafay2325) [GitHub Profile](https://github.com/AbdulRafay2325)
- Yvanvictorie Niyonzimanshuti (yvanniyonzima-ac) [GitHub Profile](https://github.com/yvanniyonzima-ac)

# Project Overview
This project demonstrates robust Infrastructure as Code (IaC) principles by deploying the Remix Weather Application onto Azure Kubernetes Service (AKS) clusters. Leveraging Terraform for infrastructure provisioning and GitHub Actions for comprehensive CI/CD automation, this project simulates a real-world multi-environment (test and production) development and deployment pipeline. It focuses on automating infrastructure provisioning, application containerization, and deployment, ensuring a consistent and reproducible setup.

## Key Technologies & Services

- Infrastructure as Code (IaC): Terraform
- Cloud Provider: Azure
- Container Orchestration: Azure Kubernetes Service (AKS)
- Database/Cache: Azure Cache for Redis (managed Redis DB)
- Container Registry: Azure Container Registry (ACR)
- CI/CD Automation: GitHub Actions
- Application Framework: Remix (Node.js)
- Terraform Backend: Azure Blob Storage

## Infrastructure Architecture

The project defines and manages Azure infrastructure through a modular Terraform setup, with state stored securely in Azure Blob Storage. The core network infrastructure is designed with a `10.0.0.0/14` Virtual Network, segmented into four dedicated subnets:
- `prod` (10.0.0.0/16)
- `test` (10.1.0.0/16)
- `dev` (10.2.0.0/16)
- `admin` (10.3.0.0/16)

Separate AKS clusters are provisioned for both test (1 node, Standard B2s) and prod (min 1, max 3 nodes, Standard B2s) environments, ensuring isolation. Each environment also has its own managed Azure Cache for Redis instance for application data caching. The Remix Weather Application is containerized and deployed to these AKS clusters, using Kubernetes Deployments and Services.

## Automated Workflows (CI/CD with GitHub Actions)

The project implements a comprehensive CI/CD strategy using GitHub Actions to automate various stages of the development and deployment lifecycle. Azure Federated Identities are configured for secure authentication.

### Static Code Analysis

- Terraform fmt & validate: Run on every push to any branch.
- TFLint & TFSec: Run on every push to any branch to ensure code quality and security best practices.

### Pull Request Workflows

- **Terraform Plan & TFLint**: Executed on every pull request to the main branch, providing a clear review of infrastructure changes before merging.

- **Application Build & Test Deployment**:

  - If application code changes in a pull request to main, the Docker image for the Remix Weather App is built and pushed to ACR (tagged with commit SHA).

  - The application is then automatically deployed to the test AKS environment. This provides immediate testing of new application features in a deployed environment for PR validation.

### Deployment to Production

- **Infrastructure Deployment**: Any infrastructure changes are applied via terraform apply only upon merge (push) to the main branch, signifying approval.

- **Application Production Deployment**: If application code changes were part of the merged pull request, the Remix Weather Application is deployed to the production AKS environment upon merge to main.

This setup ensures that infrastructure changes and application changes are managed carefully, with infrastructure updates happening after PR approval, and application deployments occurring to test environments on PR for review, and to production upon merge.

## Running the app locally

To run the Remix Weather Application locally, follow these steps:

### 1. Download the Repository

First, you need to get a copy of the project files. You can do this by cloning the GitHub repository:

```bash
git clone https://github.com/supersuper2-org/cst8918-final-project.git
cd cst8918-final-project/app
```
### 2. Install Node.js

The Remix Weather Application is a Node.js application, so you'll need Node.js and npm (Node Package Manager) installed on your system.

**Check if Node.js is installed**:
Open your terminal or command prompt and run:

```bash
node -v
npm -v
```

If you see version numbers (e.g., v18.x.x for Node.js and 9.x.x for npm), you're all set.

**If Node.js is not installed**:
Download and install the recommended LTS (Long Term Support) version of Node.js from the official website: nodejs.org. The installer typically includes npm.

### 3. Obtain an OpenWeatherMap API Key 

The application requires an API key to fetch weather data.
- Navigate to the [OpenWeatherMap website](https://openweathermap.org/api) website.
- Sign up for a free account.
- Generate an API key from your account dashboard.

### 4. Configure Environment Variables 
You'll need to provide your OpenWeatherMap API key to the application.
- In the root directory of the `app/` folder (where the `package.json` for the Remix app is located), create a new file named `.env `.
- Add your OpenWeatherMap API key to this file in the following format:
```bash
WEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY_HERE
```
Replace `YOUR_OPENWEATHER_API_KEY_HERE` with the actual key you obtained.

### 5. Install Dependencies and Run the App
Finally, install the application's dependencies and start the development server.
- From within the `app/` directory in your terminal, install the necessary Node.js dependencies:

```bash
npm install
```

Start the Remix development server:

```bash
npm run dev
```
Your Remix Weather Application should now be running locally, typically accessible in your web browser at [`http://localhost:3000`](http://localhost:3000).

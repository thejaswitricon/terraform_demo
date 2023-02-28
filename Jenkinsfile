pipeline {
  agent any
  
  tools {nodejs "NODEJS"}

  stages {
    stage('Git Checkout') {
      steps {
      git branch: 'master', url: 'https://github.com/thejaswitricon/terraform_demo.git'
             }
     }
     
    stage("set env variabl"){

            steps{

                sh 'export AWS_PROFILE=ilab'

            }

        }

        stage('Get Directory') {

            steps{

                println(WORKSPACE)

            }

        }

        stage('Terraform init'){

            steps{
                sh """
                cd dev
                terraform init"""

            }

        }

        stage('Terraform Apply'){

            steps{

                withCredentials([[

                    $class: 'AmazonWebServicesCredentialsBinding',

                    credentialsId: "AWS-access-key",

                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',

                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {

                sh """
                cd dev
                terraform apply --auto-approve"""

                }
            }
      }  

      stage ("DEV approval Destroy") {
        steps {
           echo "Taking approval from DEV Manager for QA Deployment"
           timeout(time: 7, unit: 'DAYS') {
           input message: 'Do you want to Destroy the Infra', submitter: 'admin'
           }
        }
    }
   // Destroy stage
      stage ("Terraform Destroy") {
         steps {
            steps{

                withCredentials([[

                    $class: 'AmazonWebServicesCredentialsBinding',

                    credentialsId: "AWS-access-key",

                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',

                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']])

            sh """
            cd dev
            terraform destroy --auto-approve
            """
            // sh 'terraform -chdir="./v.14/test_env" destroy --auto-approve'
        }
     }
}
  }



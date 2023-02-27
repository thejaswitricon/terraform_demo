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

                sh 'terraform apply --auto-approve'

                }

            }

      }  
  }
}
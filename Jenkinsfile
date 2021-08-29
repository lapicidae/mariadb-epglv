pipeline {
	environment {
		registry = "lapicidae/mariadb-epglv"
		registryCredential = 'dockerhub'
		//gitURL = 'https://github.com/lapicidae/mariadb-epglv.git'
		dockerImage = ''
	}
	agent any
	stages {
		stage('Clone') {
			steps{
				echo 'Cloning....'
				checkout scm
				//git gitURL
			}
		}
		stage('Build') {
			steps{
				echo 'Building....'
				script {
					dockerImage = docker.build registry + ":$BUILD_NUMBER"
				}
			}
		}
		stage('Publish') {
			steps{
				echo 'Publishing....'
				script {
					docker.withRegistry( '', registryCredential ) {
						dockerImage.push('test')
					}
				}
			}
		}
		stage('Clean') {
			steps{
				echo 'Cleaning....'
				sh "docker rmi $registry:$BUILD_NUMBER"
			}
		}
	}
}

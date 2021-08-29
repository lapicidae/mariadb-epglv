node {
	checkout scm
	stage('Build') {
		echo 'Building....'
		docker.build("mariadb-epglv:${env.BUILD_ID}")
	}
	stage('Test') {
		echo 'Testing....'
	}
	stage('Deploy') {
		echo 'Deploying....'
	}
}

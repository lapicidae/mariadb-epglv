node {
	checkout scm
	stage('Build') {
		echo 'Building....'
		def customImage = docker.build("mariadb-epglv:${env.BUILD_ID}")
		//docker.build("mariadb-epglv:${env.BUILD_ID}")
	}
	stage('Publish') {
		echo 'Publishing....'
		customImage.push('latest')
	}
	stage('Clean') {
		echo 'Cleaning....'
	}
}

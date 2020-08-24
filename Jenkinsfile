pipeline {
  agent any
  stages {
    stage('SS') {
      steps {
        git(poll: true, url: 'https://github.com/MichalDanilczyk/gearset-salesforce.git')
      }
    }

  }
}
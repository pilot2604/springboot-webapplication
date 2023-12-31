pipeline {
    agent {
        label 'ci'
    }

    tools {
        maven "maven3"
    }

    environment {
        SCANNER_HOME=tool 'sonar-scanner'

        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "172.31.3.252:8081"
        NEXUS_REPOSITORY = "devops101"
        NEXUS_CREDENTIAL_ID = "nexus-auth"

        registry = "apryell/devops101"
        registryCredential = "dockerhub-auth"
        dockerImage = ''
    }
    
    stages {

       stage ('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage ('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/pilot2604/springboot-webapplication.git'
            }
        }
        
        stage ('Test Code') {
            steps {
                sh "mvn test"
            }
        }

        stage ("SonarQube Analysis") {
            steps {
                withSonarQubeEnv(installationName: 'sonar-server', credentialsId: 'sonar-auth') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=WebApp \
                                                           -Dsonar.projectKey=WebApp '''
                }
            }
        }
        
        stage ("Quality Gate") {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage ('Build Package') {
            steps {
                sh "mvn package -DskipTests"
            }
        }
        
        stage ("Publish to Nexus Repository Manager") {
            steps {
                script {
                    pom = readMavenPom file: "pom.xml";
                    filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
                    artifactPath = filesByGlob[0].path;
                    artifactExists = fileExists artifactPath;
                    if(artifactExists) {
                        echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version}";
                        nexusArtifactUploader(
                            nexusVersion: NEXUS_VERSION,
                            protocol: NEXUS_PROTOCOL,
                            nexusUrl: NEXUS_URL,
                            groupId: pom.groupId,
                            version: pom.version,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [
                                            [artifactId: pom.artifactId,classifier: '',file: artifactPath,type: pom.packaging],
                                            [artifactId: pom.artifactId,classifier: '',file: "pom.xml",type: "pom"]
                            ]
                        );
                    } else {
                        error "*** File: ${artifactPath}, could not be found";
                    }
                }
            }
        }
        
        stage ('Building Image') {
            steps {
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER"
                }
            }
        }
        
        stage ('Upload Image to DockerHub') {
            steps {
                script {
                    docker.withRegistry( '', registryCredential ) {
                        dockerImage.push()
                    }
                }
            }
        }
        
        stage ('Deploy Image on Jenkins Agent') {
            agent {
                label 'docker'
            }
            steps {
                sh "docker run -d -p 8088:8080 $registry:$BUILD_NUMBER"
            }
        }
    }
}

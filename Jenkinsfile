pipeline {
    agent { label 'master' }
    tools {
        maven '3.9.1'
    }
    environment {
        APPLICATION_HOST = "http://170-187-231-170.ip.linodeusercontent.com"
        APPLICATION_IP = "170.187.231.170"
        APPLICATION_PORT = 8080
        APPLICATION_USERNAME = "root"
        APPLICATION_NAME = "springapp"
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "http://139-162-43-236.ip.linodeusercontent.com:8081"
        NEXUS_REPOSITORY = "maven_repository"
        NEXUS_CREDENTIAL_ID = "nexus_id"
        VERSION = "version"
        FAILED_STAGE = ""
        ERROR = ""
        HEALTH = "ACTIVE"
    }
    stages {
        stage('Build Code') {
            steps {
                script {
                    try {
                        sh 'mvn clean package -B -DskipTests'
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage('Unit Test') {
            steps {
                script {
                    try {
                        sh 'mvn test'
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml' 
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withSonarQubeEnv('sqserver') {
                            sh 'mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184:sonar'
                        }
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    try {
                        timeout(time: 3, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage("Push artifact to Nexus") {
            when {
                anyOf {
                    branch 'main'
                    branch 'uat*'
                }
                not { changeRequest() }
            }
            steps {
                script {
                    try {
                        pom = readMavenPom file: "pom.xml";
                        filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                        echo "filesByGlob: $filesByGlob";
                        file = filesByGlob[0].path;
                        withCredentials([usernameColonPassword(credentialsId: 'nexus_id', variable: 'NEXUS_CREDENTIAL')]) {
                            sh """
                                curl -v -u \$NEXUS_CREDENTIAL "$NEXUS_URL/service/rest/v1/components?repository=$NEXUS_REPOSITORY" \
                                -F "maven2.groupId=$pom.groupId" \
                                -F "maven2.artifactId=$pom.artifactId" \
                                -F "version=${pom.version}_${env.BUILD_NUMBER}" \
                                -F "maven2.asset1=@$file" \
                                -F "maven2.asset1.extension=$pom.packaging"
                            """
                        }
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage('Pull artifact from Nexus') {
            when {
                anyOf {
                    branch 'main'
                    branch 'uat*'
                }
                not { changeRequest() }
            }
            steps {
                script {
                    try {
                        pom = readMavenPom file: "pom.xml";
                        filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                        ARTIFACT_URL = "$NEXUS_URL/service/rest/v1/search/assets/download?sort=$VERSION&repository=$NEXUS_REPOSITORY&maven.groupId=$pom.groupId&maven.artifactId=$pom.artifactId&maven.baseVersion=${pom.version}_${env.BUILD_NUMBER}&maven.extension=$pom.packaging";
                        sshagent(['root_sshagent']) {
                            withCredentials([usernameColonPassword(credentialsId: 'nexus_id', variable: 'NEXUS_CREDENTIAL')]) {
                                sh "ssh -o StrictHostKeyChecking=no -l $APPLICATION_USERNAME $APPLICATION_IP 'cd /usr/local/bin && curl -fsSL -u $NEXUS_CREDENTIAL -o ${APPLICATION_NAME}.jar \"$ARTIFACT_URL\"'";
                            }
                        }
                        
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage('Deploy application') {
            when {
                anyOf {
                    branch 'main'
                    branch 'uat*'
                }
                not { changeRequest() }
            }
            steps {
                script {
                    try {
                        sshagent(['root_sshagent']) {
                            sh "ssh -o StrictHostKeyChecking=no -l $APPLICATION_USERNAME $APPLICATION_IP 'systemctl restart springapp.service'";
                        }
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
        stage('Check health application') {
            when {
                anyOf {
                    branch 'main'
                    branch 'uat*'
                }
                not { changeRequest() }
            }
            steps {
                script {
                    try {
                        sh "curl --retry 5 --retry-all-errors $APPLICATION_HOST:$APPLICATION_PORT > /dev/null";
                    } catch(e) {
                        FAILED_STAGE=env.STAGE_NAME;
                        HEALTH="DIED";
                        ERROR=e.getMessage();
                        error "[${FAILED_STAGE}]: ${e.getMessage()}";
                    }
                }
            }
        }
    }
    post {
        success {
            //MS TEAMS
            office365ConnectorSend (
                webhookUrl: 'https://fptsoftware362.webhook.office.com/webhookb2/4c942833-9eb5-4e2d-b488-423c5d85f2f4@f01e930a-b52e-42b1-b70f-a8882b5d043b/JenkinsCI/b69c758d8a33434f99421ce205bfe5ab/2402f6d5-457e-4fb9-90b5-89b85b622857',
                color: '00ff00',
                status: 'Build Success',
                message: "Latest status of build #${env.BUILD_NUMBER}"
            )

            //OUTLOOK
            // office365ConnectorSend (
            //     webhookUrl: 'https://fptsoftware362.webhook.office.com/webhookb2/871ceeb8-22bd-40eb-a55d-4d6b455b4b46@f01e930a-b52e-42b1-b70f-a8882b5d043b/JenkinsCI/7afd8c79479b4d24aec701a8829398ae/2402f6d5-457e-4fb9-90b5-89b85b622857',
            //     color: '00ff00',
            //     status: 'Build Success',
            //     message: "Latest status of build #${env.BUILD_NUMBER}"
            // )
            
            //SLACK
            slackSend (
                color: "good", 
                message: "SUCCESSFUL: ${env.JOB_NAME} \nBuild #${env.BUILD_NUMBER} - ${env.BUILD_URL}"
            )

            //GMAIL
            emailext (
                to: "classic.nct@gmail.com",
                subject: "SUCCESSFUL - ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """<h2>SUCCESSFUL - ${env.JOB_NAME} Build #${env.BUILD_NUMBER}:</h2>
                    <p>HEALTH: <span style="color: green; font-weight: bold;">${HEALTH}</span></p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>""",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            //MS TEAMS
            office365ConnectorSend (
                webhookUrl: 'https://fptsoftware362.webhook.office.com/webhookb2/4c942833-9eb5-4e2d-b488-423c5d85f2f4@f01e930a-b52e-42b1-b70f-a8882b5d043b/JenkinsCI/b69c758d8a33434f99421ce205bfe5ab/2402f6d5-457e-4fb9-90b5-89b85b622857',
                color: 'ff0000',
                status: 'Build Failed',
                message: "Build #${env.BUILD_NUMBER}- Failed at \"${FAILED_STAGE}\" stage"
            )

            //OUTLOOK
            // office365ConnectorSend (
            //     webhookUrl: 'https://fptsoftware362.webhook.office.com/webhookb2/871ceeb8-22bd-40eb-a55d-4d6b455b4b46@f01e930a-b52e-42b1-b70f-a8882b5d043b/JenkinsCI/7afd8c79479b4d24aec701a8829398ae/2402f6d5-457e-4fb9-90b5-89b85b622857',
            //     color: 'ff0000',
            //     status: 'Build Failed',
            //     message: "Build #${env.BUILD_NUMBER} - Failed at \"${FAILED_STAGE}\" stage"
            // )

            //SLACK
            slackSend (
                color: "danger", 
                message: "FAILED: ${env.JOB_NAME} at \"${FAILED_STAGE}\" stage \nBuild #${env.BUILD_NUMBER} - ${env.BUILD_URL} \nERROR: ${ERROR}"
            )

            //GMAIL
            emailext (
                to: "classic.nct@gmail.com",
                subject: "FAILED - ${env.JOB_NAME} at \"${FAILED_STAGE}\" stage - Build #${env.BUILD_NUMBER}",
                body: """<h2>FAILED - ${env.JOB_NAME} at \"${FAILED_STAGE}\" stage - Build #${env.BUILD_NUMBER}:</h2>
                    <p>ERROR: ${ERROR}</p>
                    <p>HEALTH: <span style="color: red; font-weight: bold;">${HEALTH}</span></p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>""",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']],
            )
        }
    }
}
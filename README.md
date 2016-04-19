# vsotasks

The repo contains build tasks written for build.vnext used by Visual Studio Online and Teamfoundation Server On Premise

## Uploading Tasks

You need to upload these tasks to your TFS / VSTS server.

Clone the repo
Install tfx-cli
Run npm install in the root folder.
Run npm install in each Task folder.
Run tfx login to login to your server.
Run tfx build tasks upload --task-path <path to task folder> to upload a task, where is the path to the Task folder of the task you want to upload
The task should now be available on your TFS / VSO.

## Tasks
* TFSBuildChain
Trigger a build when another build is finished.

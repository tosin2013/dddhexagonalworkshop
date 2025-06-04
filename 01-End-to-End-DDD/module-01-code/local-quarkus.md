# Running Quarkus Locally

## System Requirements

- **Java 21 or higher** installed
- **Maven 3.8+** for dependency management
- **IDE** of choice (IntelliJ IDEA, VS Code, Eclipse)
- **Docker** (optional - for running external services manually)

If you don't meet these requirements we recommend using GitHub Codespaces.

## Command Line Setup

Run the following from your command line:

```bash
mvn io.quarkus.platform:quarkus-maven-plugin:3.10.0:create \
  -DprojectGroupId=org.example \
  -DprojectArtifactId=attendees \
  -DclassName="org.example.AttendeeResource" \
  -Dpath="/attendees" \
  -Dextensions="rest-jackson,hibernate-orm-panache,jdbc-postgresql,quarkus-messaging-kafka"
```

This will create a project in a directory named "attendees."  Open the project in your IDE of choice.  Your workshop authors are familiar with IntelliJ and Visual Studio Code and can provide assistance with either of those if necessary.

For Visual Studio Code simply open the "attendees" folder or change into the directory and run:

```bash
code .
``


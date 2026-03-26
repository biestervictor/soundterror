cd /Users/victorbiester/IdeaProjects/soundterror
docker build -t soundterror:latest .
docker run --rm --name soundterror -p 8443:8443 soundterror:latest

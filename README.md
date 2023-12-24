# Wallarm Base Docker Image for Heroku

This repository contains the Dockerfile and necessary resources to build a Wallarm base Docker image for running on Heroku. This image is designed to simplify the deployment process of Wallarm-protected applications on the Heroku platform.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [License](#license)


## Prerequisites

Before you begin, ensure you have met the following requirements:

- You have a Heroku account. If you don't have one, sign up [here](https://www.heroku.com/).
- You have installed the latest version of [Docker](https://www.docker.com/).
- You have installed the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).


## Usage

To use the Wallarm base Docker image for your Heroku application, follow these steps:

1. Create a new Heroku application:

```bash
heroku create your-app-name
```

2. Set [container](https://devcenter.heroku.com/categories/deploying-with-docker) stack:

```bash
heroku stack:set container
```

3. Create a `Dockerfile` file in the root of your app directory. Install all necessary dependencies such as your app's runtime. For NodeJS, use the following example:

```dockerfile
FROM bonakodo/wallarm-heroku:4.8.4@sha256:ec4d8c94de76a385bc7eab01b43290da8a377a40985f889b776bf83199cff45e

# Install NodeJS v20 from NodeSource
ENV NODE_MAJOR=20

RUN apt-get update \
  && apt-get install -qqy ca-certificates curl gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update \
  && apt-get install nodejs -qqy \
  && apt-get clean

ADD . /opt/webapp
WORKDIR /opt/webapp

# Install production dependencies and build the app, if necessary
RUN npm install --omit=dev && npm run build
ENV npm_config_prefix /opt/webapp

# Note that in private spaces the `run` section of heroku.yml is ignored
# See: https://devcenter.heroku.com/articles/build-docker-images-heroku-yml#known-issues-and-limitations
CMD ["npm", "run", "start"]
```

4. Create a [`heroku.yml`](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml) configuration file as follows:

```yaml
# heroku.yml
build:
  docker:
    web: Dockerfile
```

5. Modify your app to listen on `/tmp/unix.websocket` instead of `$PORT` as `$PORT` is already occupied by nginx. For example, in an express app configure port as follows:

```javascript
// app.js
const app = require('express')()

let port = process.env.PORT || 3000 // Wallarm is not configured, listen on $PORT
if(process.env.WALLARM_API_TOKEN) port = '/tmp/nginx.socket' // Wallarm is configured

app.listen(port, (err) => {
	if (err) throw err
	console.log(`> App is listening on ${port}`)
})

app.get('/', (req, res) => {
  res.send('This app is protected by Wallarm')
})
```

6. Push your app
	
```bash
git add Dockerfile heroku.yml app.js package.json
git commit -m "Add Heroku docker config"
git push heroku master
```


## Configuration

The Wallarm base Docker image can be configured using environment variables. The following variables are available:

- `WALLARM_API_TOKEN`: Your Wallarm API token or node token. If not set, the image skips Wallarm launch and only runs the command specified in CMD (see [entrypoint.sh](entrypoint.sh)).
- `WALLARM_API_HOST`: The Wallarm Cloud API hostname. Use `us1.api.wallarm.com` for the US cloud or `api.wallarm.com` for the EU cloud (default: `us1.api.wallarm.com`).
- `WALLARM_LABELS`: The Wallarm node label (default: `group=heroku`). The group setting is required if you use the API token in place of the node token. 

Set these variables using the `heroku config:set` command:

```bash
heroku config:set WALLARM_API_TOKEN=your-wallarm-api-token
heroku config:set WALLARM_LABELS=group=myfancyapp
```

## Troubleshooting

If you encounter any issues while using the Wallarm base Docker image, check the Heroku logs for any error messages:

```bash
heroku logs --tail
```

To build this image and debug it locally run:

```bash
docker build -t bonakodo/wallarm-heroku:4.6 --platform linux/amd64 .
```

If you need further assistance, please create an issue in this repository.

## License

This dockerfile and configs are licensed under the [BSD-3-Clause](LICENSE) license.
Wallarm node is licensed under its [Software License Agreement](https://www.wallarm.com/end-user-license-agreement).
# Use an official Node.js runtime as a parent image
FROM node:18.18.0 AS build

# Set the working directory in the container
WORKDIR /usr/src/requestly

# Set Node.js memory limit
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./
COPY common/rule-processor/package*.json ./common/rule-processor/
COPY app/.npmrc app/package*.json ./app/

# Install dependencies for the main project
RUN npm install

# Install dependencies for the rule-processor
WORKDIR /usr/src/requestly/common/rule-processor
RUN npm install

# Install dependencies for the React app
WORKDIR /usr/src/requestly/app
RUN npm install

# Copy the rest of the project files
WORKDIR /usr/src/requestly
RUN mkdir public
COPY index.js ./
COPY common ./common
COPY app ./app

# Build the rule-processor
WORKDIR /usr/src/requestly/common/rule-processor
RUN npm run build

# Build the React app
WORKDIR /usr/src/requestly/app
RUN npm run build

# Use a smaller base image for the final image
FROM nginx:alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy only the necessary files from the build stage
COPY nginx.conf /etc/nginx/conf.d/nginx.conf
COPY --from=build /usr/src/requestly/app/build ./

# Expose the port the app runs on
EXPOSE 3000

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]

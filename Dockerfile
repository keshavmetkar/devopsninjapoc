FROM node:alpine
COPY  ./devopsninjapoc/test-nodeapp-1-task .
RUN npm install
RUN npm build
CMD ["npm", "start"]

FROM node:alpine
COPY  ./test-nodeapp-1-task .
RUN npm install
RUN npm build
CMD ["npm", "start"]

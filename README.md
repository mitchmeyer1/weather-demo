# README

To get started, assure you have docker and docker-compose working on your local machin. Then navigate to this directory in terminal and enter 
```
docker-compose up --build
```



Features
-Fetches current weather and weekly forcast
-Displays to user in front end at localhost:3000
-Seperate API vs Web routes
-web local storage caching of inputted address
-redis storage caches weather data for each zip code for 30 min
-rate limiting 20 requests per IP per min
-Conversion between F and C
-No persistent storage
-Out of the box front end css kit used, custom css and front end work minimal
# дз 3 по ипр

## запуск

cp .env.example .env

docker compose up -d --build

после запуска приложение доступно на http://127.0.0.1:8080/

в .env можно поменять настройки

- GREETING — приветствие
- APP_PORT — порт

## проверка счетчика

посмотреть текущее значение

curl -fsS http://127.0.0.1:8080/

увеличить счетчик на 1

curl -fsS -X POST http://127.0.0.1:8080/increment

## запуск скрипта проверки

./scripts/check.sh

резервная копия redis сохраняется в redis-backup.tar.gz

## остановка контейнеров

docker compose down

## 4 балла

собрала образ

docker build -t hse-docker-hw:1 .

запустила контейнер с приветствием Hello

docker run -d --name hse-counter -p 127.0.0.1:8080:8000 -e GREETING=Hello hse-docker-hw:1

проверила счетчик через curl
начальное значение 0 после двух post запросов значение 2

логи docker logs hse-counter

2026-11-23 19:21:28,272 listening port=8000 storage=sqlite
2026-11-23 19:21:44,790 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-23 19:21:48,720 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-23 19:21:48,869 http 172.17.0.1 "GET /favicon.ico HTTP/1.1" 404 -
2026-11-23 19:22:27,938 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-23 19:23:17,199 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-23 19:23:39,064 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -

## 6 баллов

настроила запуск через docker compose и подключила именованный volume counter-data к /data

docker compose up -d --build

после post запроса счетчик стал равен 1

{"greeting": "Hello", "count": 1, "hostname": "e9076c8f4d95", "storage": "sqlite"}

удалила и заново создала контейнер

docker compose down
docker compose up -d

проверила счетчик

curl -fsS http://127.0.0.1:8080/

{"greeting": "Hello", "count": 1, "hostname": "1b1fdd63e36e", "storage": "sqlite"}

hostname поменялся а значение счетчика сохранилось

## 8 баллов

добавила redis в compose.yaml подключила volume и настроила healthcheck для обоих сервисов

увеличила счетчик до 3 и пересоздала контейнеры

docker compose down
docker compose up -d

curl -fsS http://127.0.0.1:8080/

{"greeting": "Hello", "count": 3, "hostname": "1239b39ab96e", "storage": "redis"}

проверила работу приложения при отключении redis

docker compose stop redis

curl -i http://127.0.0.1:8080/healthz
200 OK

curl -i http://127.0.0.1:8080/readyz
503 Service Unavailable

curl -i -X POST http://127.0.0.1:8080/increment
503 Service Unavailable

запустила redis обратно

docker compose start redis

curl -fsS http://127.0.0.1:8080/

{"greeting": "Hello", "count": 3, "hostname": "1239b39ab96e", "storage": "redis"}

curl -fsS -X POST http://127.0.0.1:8080/increment

{"greeting": "Hello", "count": 4, "hostname": "1239b39ab96e", "storage": "redis"}

счетчик сохранился и приложение продолжило работать без перезапуска

## 10 баллов

настроила запуск приложения не от root

docker compose exec app id

uid=10001 gid=10001 groups=10001

проверила что файловая система доступна только для чтения

docker compose exec app sh -c 'touch /testfile'

touch: cannot touch '/testfile': Read-only file system

ограничила память до 256 мб и cpu до 1

docker inspect --format '{{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' hse-docker-hw-app-1

268435456 1000000000

написала скрипт scripts/check.sh и запустила его два раза

### первый запуск

./scripts/check.sh

{"greeting": "Hello", "count": 0, "hostname": "d06c18810377", "storage": "redis"}
POST /increment: 200
POST /increment: 200
POST /increment: 200
{"greeting": "Hello", "count": 3, "hostname": "d06c18810377", "storage": "redis"}
{"greeting": "Hello", "count": 3, "hostname": "2319b53be338", "storage": "redis"}
GET /healthz: 200
GET /readyz: 503
POST /increment: 503
{"greeting": "Hello", "count": 3, "hostname": "2319b53be338", "storage": "redis"}
POST /increment: 200
{"greeting": "Hello", "count": 4, "hostname": "2319b53be338", "storage": "redis"}
OK

### второй запуск

./scripts/check.sh

{"greeting": "Hello", "count": 0, "hostname": "dffe19af9097", "storage": "redis"}
POST /increment: 200
POST /increment: 200
POST /increment: 200
{"greeting": "Hello", "count": 3, "hostname": "dffe19af9097", "storage": "redis"}
{"greeting": "Hello", "count": 3, "hostname": "6601feae8374", "storage": "redis"}
GET /healthz: 200
GET /readyz: 503
POST /increment: 503
{"greeting": "Hello", "count": 3, "hostname": "6601feae8374", "storage": "redis"}
POST /increment: 200
{"greeting": "Hello", "count": 4, "hostname": "6601feae8374", "storage": "redis"}
OK

оба запуска прошли успешно тестовые контейнеры и volume удалились

проверила содержимое резервной копии

tar -tzf redis-backup.tar.gz

./
./appendonlydir/
./appendonlydir/appendonly.aof.1.base.rdb
./appendonlydir/appendonly.aof.1.incr.aof
./appendonlydir/appendonly.aof.manifest
./dump.rdb

# VladimirDe_microservices

### Homework-21: Введение в Kubernetes

Основное задание: Разобрать на практике все компоненты kubernetes, развернуть их вручную используя Hard Way, ознакомиться с описанием основных примитивов куввше приложения и его дальнейшим запуском в Kubernetes

Задание со*: Описать установку компонентов kubernetes из туториала `Kubernetes The Hard Way` в виде Ansible-плейбуков в папке `kubernetes/ansible`

### 21.1 Что было сделано

- Пройден туториал `Kubernetes The Hard Way` вручную, проверена загрузка deployment-ов (ui, post, mongo, comment) и запуск подов

- Написаны ansible плейбуки полностью автоматизирующие `Kubernetes The Hard Way`

```
02-client-tools.yml
03-create-controller-instance.yml
03-create-worker-instance.yml
03-provisioning-compute-resources.yml
04-certificate-authority.yml
04-copy-creds-to-controller.yml
04-copy-creds-to-worker.yml
04-prepare-node.yml
04-worker-instance-certificate.yml
05-generate-kubeconfigs.yml
05-generate-service-kubeconfig.yml
05-generate-worker-kubeconfig.yml
06-data-encryption.yml
07-bootstraping-etcd.yml
08-bootstrapping-kubernetes-controllers.yml
08-kubernetes-frontend-load-balancer.yml
09-bootstrapping-kubernetes-workers.yml
10-configuring-kubectl.yml
11-pod-network-routes.yml
12-dns-addon.yml
kubernetes_the_hard_way.yml
```

### 21.2 Как запустить проект

Предполагается, что gcloud уже настроен и есть учетная запись сервисного аккаунта google из под которой будет выполняться создание в GCP инстансов, сетей и т. д.

```
cd kubernetes/ansible
virtualenv .venv
source .venv/bin/activate
pip install -r requirements.txt
export GCE_REGION=$(gcloud config get-value compute/region 2> /dev/null)
export GCE_CREDENTIALS_FILE_PATH=~/.ansible/gce-service-account.json
export GCE_EMAIL=user@docker-1234.iam.gserviceaccount.com
export GCE_PROJECT=docker-1234
ansible-playbook -K kubernetes_the_hard_way.yml
```

### 21.3 Как проверить проект

Для проверки инсталляции kubernetes нужно:

- Выполнить шаги описанные в <https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-smoke-test.md>

- Проверить запуск подов `ui, post, mongo, comment`

```
cd kubernetes/reddit
for DEPLOYMENT in *.yml; do kubectl apply -f $DEPLOYMENT;done
```

# Homework - monitoring-2
  #### Основное задание
  - Т.к. мы разделили сервисы приложения и сервисы мониторинга на разные compose файлы, то необходимо создать общие сети вручную и отметить их как 'external' в файлах docker-compose:
    -   ```docker network create --subnet 10.0.2.0/24 backend && docker network create --subnet 10.0.1.0/24 frontend```
  ### Задания со *:
  #### В Makefile добавлены новые сервисы
  #### Добавить сбор метрик, отдаваемых докер демоном в prometheus:
   - Думал как лучше сделать, чтобы достучатся до хоста из контейнера с прометеем. Решил сделать ещё одну сеть, в которой явно задал адрес gateway:    
      - ``` docker network create --subnet 10.0.3.0/30 --gateway 10.0.3.1 hostnet ```
      
        Эту сеть добавляем как external в docker-compose-monitoring.yml и подключаем к контейнеру с прометеем. Также необходимо добавить правило файрвола, которое разрешает подключение к хосту c интерфейса сети hostnet - ``` sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 4 -i br-14d3a37d8190 -j ACCEPT && sudo firewall-cmd --reload ```

        В /etc/docker/daemon.json задаём адрес интерфейса в созданной сети, на котором будет доступен просмотр метрик - 10.0.3.1  (чтобы порт был доступен только для одной сети )
  #### Сбор метрик через telegraf
   - Изначально поднял контейнер с telegraf и забирал метрики в прометей, но не нашёл нормальных дашбордов для графаны в такой связке. Потому добавил ещё контейнер с influxdb, в которую telegraf отправляет метрики. И в графане подключил influxdb как datasource. Дашборд положил в 'monitoring/grafana/dashboards/docker-metrics-per-container.json'
  #### Настройка email уведомлений в alertmanager
   - Сгенерировал application password для gmail аккаунта и добавил отправку уведомлений на почту. Логин и пароль передаются через ENV 

## Homework-18: Введение в мониторинг. Системы мониторинга

Основное задание: запуск, конфигурация Prometheus; мониторинг состояния микросервисов; сбор метирк хоста с использованием экспортера

Задание со *: добавить в Prometheus мониторинг mongodb, зафиксировав версию образа экспортера на последнюю стабильную

Задание со *: добавить в Prometheus blackbox мониторинг сервисов comment, post, ui, зафиксировав версию образа экспортера на последнюю стабильную

Задание со *: добавить Makefile, которые умеет собирать и пушить образы docker контейнеров

### 18.1 Что было сделано

- Изменена структура каталогов проекта, добавлены каталоги docker, monitoring

- В конфигурацию docker compose добавлен сервис prometheus

- В конфигурацию prometheus и docker compose добавлен node-exporter

- Добавлен Dockerfile для сборки mongodb prometheus exporter от percona (результирующий образ построен на scratch), добавлен мониторинг mongodb в prometheus и docker compose

- Добавлен Dockerfile для сборки blackbox exporter; добавлен мониторинг микросервисов ui (blackbox-http), post (blackbox-tcp), comment (blackbox-tcp)

- Добавлен Makefile для сборки образов docker контейнеров и их пуша в docker hub; добавлена возможность старта и удаления микросервисов через Makefile

### 18.2 Как запустить проект

- Предполагается, что уже установлен **docker, docker compose**

- Установить make

```bash
apt-get update && apt-get install make
```

- Собрать образы контейнеров и локально запустить их через docker compose можно командой

```bash
make up
```

- Собрать образы контейнеров и запушить их в docker hub репозиторий можно командой

```bash
make all
```

- Остановить и удалить запущенные контейнеры

```bash
make down
```

Примеры работы с отдельными микросервисами:

- Собрать docker образ микросервиса (ui) можно командой

```bash
make ui_build
```

- Запушить docker образ микросервиса (ui) можно командой

```bash
make ui_push
```

- Собрать и запушить образ отдельного микросервиса (ui)

```bash
make ui
```

### 18.3 Как проверить проект

- В корне репозитория выполнить

```bash
make up
```

После сборки и запуска контейнеров по адресу <http://localhost:9292> будет доступно reddit приложение

По адресу <http://localhost:9090> будет доступен интерфейс prometheus

- В корне репозитория выполнить

```bash
make all
```

После сборки и пуша, образы контейнеров будут доступны в dockerhub по ссылке: <https://hub.docker.com/r/vladimirdenisov69>

## Homework-17: Устройство Gitlab CI. Непрерывная поставка

 - Основные задания: расширить существующий пайплайн в gilab ci, определить окружения

 - Задания со *: при пуше новой ветки должен создаваться сервер для окружения с возможностью удалить его кнопкой

 - Задания с **: в шаг build добавить сборку контейнера с приложением reddit, контейнер деплоить на созданный для ветки сервер

## 17.1 Что было сделано

 - В конвейер непрервывной поставки были добавлены шаги staging, production использующие различные окружения

 - В ansible создана роль reddit_monolith для деплоя контейнера на docker хост

 - Изменен плейбук reddit_app.yml с учетом reddit_monolith

 - Написан Dockerfile для сборки docker образа reddit приложения

 - Написан Dockerfile для сборки docker образа провижинера приложения, содержащий в себе terraform, ansible

 - В docker_host module (terraform) добавлены ресурсы для провижинга приложения

 - В шаг build добавлена сборка образов reddit, app_provision с их последующим сохранением в docker registry

 - В конвейер непрервывной поставки был добавлен шаг branch_start_review для автоматического создания серверов для каждой ветки и деплоя приложения reddit. При этом, для каждой ветки через terrafrom workspace создается инстанс docker хоста, на который плейбуком reddit_app.yml деплоится reddit приложение

 - В конвейер непрервывной поставки был добавлен шаг branch_stop_review для удаления серверов

## 17.2 Как запустить проект

Предполагается, что уже настроен gitlab сервер и зарегистрирован gitlab runner

В настройках CI/CD gitlab server нужно добавить следующие переменные:

CI_GOOGLE_CREDENTIALS - переменная для подключения terraform к GCP

DOCKER_REGISTRY_USER - пользователь docker hub registry

DOCKER_REGISTRY_PASSWORD - пароль docker hub registry

GCE_SERVICE_ACCOUNT - содержимое credentials файла от сервисного аккаунта GCP. Используется для настройки динамического инвентори через gce.py (роль ansible gce_py)

GCP_PROJECT - название проекта в GCP

SSH_PRIVATE_KEY, SSH_PUBLIC_KEY - пара ssh ключей для подключения к docker host (используются при провиженге через ansible)

После настройки environment переменных при пуше новой ветки в gitlab будет автоматичкски создано окружение и на него развернуто reddit приложение

## 17.3 Как проверить проект

После успешного выполнения шага branch_start_review, приложение будет доступно по адресу http://docker_host_external_ip:9292
```
Outputs:

docker_host_external_ip = [
    35.240.19.232
]
Job succeeded
```
После проверки приложения, сервер можно удалить нажав на branch_stop_review

## Homework-16: Gitlab CI. Построение процесса непрервыной интеграции

 - Основные задания: подготовить инсталляцию Gitlab CI, подготовить репозиторий с кодом приложения, описать для приложения этапы непрервыной интеграции

 - Задания со *: добавить интеграцию pipeline со slack чатом

## 16.1 Что было сделано

 - Проинсталирован gitlab (self-hosted, docker)

 - Добавлена конфигурация пайплана gitlab, зарегестрирован один ранер

 - Добавлено reddit приложение и тесты для него, настроен запуск тестов в gitlab CI/CD

 - Добавлена интеграция со slack чатом https://otus-devops.slack.com/messages/DATGX1LBH/

К сожалению токен не удалось достать и передать в gitlab-runner register, а без него вся автоматизация не имеет смысла - всё равно есть ручной шаг.

## 16.2 Как запустить проект

После настройки CI/CD в gitlab, можно запушить изменения и проверить, что статус пайплайна будет passed
```
git remote add gitlab http://<your-vm-ip>/homework/example.git
git push gitlab gitlab-ci-1
```

## 16.3 Как проверить проект

открыть прилжение redit по адресу http://<ip>:9292
 
## Homework-15: Docker сети, docker-compose

Основные задания:

- Работа с none, host, bridge сетями docker
- Установка docker-compose
- Сборка образов приложения reddit с помощью docker-compose
- Запуск приложения reddit с помощью docker-compose
- Изменение префикса в docker-compose

В docker-compose имена префиксов контейнеров задаются env переменной **COMPOSE_PROJECT_NAME**, которая по умолчанию равна названию каталога с проектом:

```bash
cd /some/path/to/project_directory
basename $(pwd)
```

Эту переменную можно переопределить в **.env** файле:

```bash
# Defaul setting COMPOSE_PROJECT_NAME to the basename
# Change this value to setup containers prefix name
# COMPOSE_PROJECT_NAME=
```

Задания со *:

- Создание docker-compose.override.yml, который позволяет изменять код приложений без пересборки docker образов и запускать ruby приложения в режиме отладки с двумя воркерами.

### 15.1 Что было сделано

- Создан контейнер с none network driver, проверена конфигурация его сетевых интерфейсов

- Создан контейнер с host network driver, проверена конфигурация его сетевых интерфейсов

- Созданы контейнеры с bridge network driver, которым были присвоены сетевые алиасы

- Созданы docker сети front_net (подключены контейнеры ui, post, comment), back_net (подключены контейнеры mongo, post, comment)

- Проверена работа сетевого стека linux (net namespaces, iptables) при работе с docker

- Установлен docker-compose, написан docker-compose.yml для автоматического создания и запуска docker ресурсов

- Создан .env файл для настройки docker-compose через environment переменные (версии образов, префикс проекта и т. д.)

- Создан docker-compose.override.yml позволяющий изменять код приложения без пересоздания образа и запускать puma сервер в режиме отладки. Соответственно, изменены Dockerfile в микросервисах comment, ui, post для поддержки docker-compose.override.yml

### 15.2 Как запустить проект

- Предполагается, что перед запуском проекта уже существует **docker-host** и имеет адрес **docker_host_ip**, а также установлен **docker-compose**

```bash
docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER        ERRORS
docker-host   *        google   Running   tcp://docker_host_ip:2376           v18.06.0-ce

eval $(docker-machine env docker-host)
```

```bash
cd src
docker-compose up -d
```

### 15.3 Как проверить проект

После запуска, reddit приложение будет доступно по адресу <http://docker_host_ip:9292>, при этом можно создать пост и оставить комментарий.



## Homework-14: Docker образы. Микросервисы

### 14.1 Что было сделано

Основные задания:

- Созданы docker образы для микросервисов comment, ui, post
- Создана docker сеть для приложения reddit
- Создан docker том для данных mongodb
- Запущены контейнеры на основе созданных образов

Задания со *:

- Изменение сетевых алиасов, использование env переменных

```bash
# Пример решения
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post_alias -e 'POST_DATABASE_HOST=post_db' vladimirdenisov69/post:1.0
docker run -d --network=reddit --network-alias=comment_alias -e 'COMMENT_DATABASE_HOST=comment_db' vladimirdenisov69/comment:1.0
docker run -d --network=reddit --network-alias=ui_alias -e 'POST_SERVICE_HOST=post_alias' -e 'COMMENT_SERVICE_HOST=comment_alias' vladimirdenisov69/ui:1.0
```

Задания со *:

- Уменьшены размеры образов comment, ui, post

```bash
# Размеры образов ui
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
vladimirdenisov69/ui      3.2                 17812b3e799b        11 seconds ago      34.5MB # alpine, multi-stage build, cache cleaning
vladimirdenisov69/ui      3.1                 33170cebce0d        4 minutes ago       37.5MB # alpine, multi-stage build
vladimirdenisov69/ui      3.0                 b6012d168c44        14 minutes ago      210MB # alpine
vladimirdenisov69/ui      2.0                 5f494c53de90        23 minutes ago      460MB # ubuntu 16.04
vladimirdenisov69/ui      1.0                 1dc4afe3d94c        26 minutes ago      777MB # ruby 2.2
```

```bash
# Размеры образов post
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
vladimirdenisov69/post    2.2                 e13a2539eef3        6 minutes ago       35.1MB # alpine:3.8, multi-stage build, venv packages cleaning, pyc files removing
vladimirdenisov69/post    2.1                 a4978e47831e        13 minutes ago      57.5MB # alpine:3.8, multi-stage build, venv packages cleaning
vladimirdenisov69/post    2.0                 324095723244        21 minutes ago      62.6MB # alpine:3.8, multi-stage build
vladimirdenisov69/post    1.0                 228a932d5c0d        3 hours ago         102MB # python:3.6.0-alpine
```

```bash
# Размеры образов comment
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
vladimirdenisov69/comment   2.0                 d42d889bed54        18 seconds ago      30.1MB # alpine, multi-stage build, cache cleaning
vladimirdenisov69/comment   1.0                 d1e034889328        4 hours ago         769MB # ruby 2.2
```

### 14.2 Как запустить проект

- Предполагается, что перед запуском проекта уже существует **docker-host** и имеет адрес **docker_host_ip**

```bash
docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER        ERRORS
docker-host   *        google   Running   tcp://docker_host_ip:2376           v18.06.0-ce

eval $(docker-machine env docker-host)
```

- Создание docker образов микросервисов comment, post, ui

```bash
cd src
docker build -t vladimirdenisov69/comment:2.0  ./comment
docker build -t vladimirdenisov69/post:2.2  ./post-py
docker build -t vladimirdenisov69/ui:3.2  ./ui
```

- Запуск проекта

```bash
docker network create reddit
docker volume create reddit_db

docker run -d --network=reddit --network-alias=post_db \
 --network-alias=comment_db -v reddit_db:/data/db mongo:latest

docker run -d --network=reddit --network-alias=post vladimirdenisov69/post:2.2

docker run -d --network=reddit --network-alias=comment vladimirdenisov69/comment:2.0

docker run -d --network=reddit -p 9292:9292 vladimirdenisov69/ui:3.2
```

### 14.3 Как проверить проект

После запуска, reddit приложение будет доступно по адресу <http://docker_host_ip:9292>, при этом можно создать пост и оставить комментарий.


## Homework-13: Docker контейнеры. Docker под капотом
### 13.1 Что было сделано
Основные задания:

 - Создание docker host в GCP через docker machine

 - Создание образа docker контейнера otus-reddit:1.0

 - Создание репозитория на docker hub и загрузка в него образа otus-reddit:1.0

Задания со *:

 - В docker-monolith/infra/ansible добавлена конфигурация ansible для настройки docker host (роль docker_host) и настроено dynamic inventory через gce.py

 - В docker-monolith/infra/packer добавлена конфигурация для создания образа с уже установленным docker

 - В docker-monolith/infra/terraform добавлена конфигурация для подъема инстансов docker-host-xxx, количество которых, задается переменной count

## 13.2 Как запустить проект
### 13.2.1 Шпаргалка по командам docker, docker machine. 
#### Создание образа otus-reddit
```
docker-machine create --driver google  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts  --google-machine-type n1-standard-1   --google-zone europe-west1-b  docker-host

docker-machine ls

docker-machine env docker-host
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://ip:port"
export DOCKER_CERT_PATH="/some/path/to/.docker/machine/machines/docker-host"
export DOCKER_MACHINE_NAME="docker-host"
# Run this command to configure your shell:
# eval $(docker-machine env docker-host)

eval $(docker-machine env docker-host)
```
#### Запустить htop (PID из container namespaces)
```docker run --rm -ti tehbilly/htop```

#### Запустить htop (PID из host namspaces)
```docker run --rm --pid host -ti tehbilly/htop```

```
docker run --help | grep "\-\-pid "
      --pid string                     PID namespace to use
```

-t - tag (--tag=)
docker build -t reddit:latest .

-d background mode (--detach=true)
--network - use host network
```docker run --name reddit -d --network=host reddit:latest```

#### Создать  tag алиас на reddit:latest
```docker tag reddit:latest vladimirdenisov69/otus-reddit:1.0```
#### Запушить образ в docker registy
```
docker login
docker push vladimirdenisov69/otus-reddit:1.0
```
#### Запустить существующий контейнер
```
docker stop reddit
docker start reddit
```
#### Логи
```docker logs reddit -f```

#### Запустить bash
```docker exec -it reddit bash```

#### Удалить контейнер
```docker rm reddit```

#### Запуск контейнера без запуска приложения
```
docker run --name reddit --rm  -it vladimirdenisov69/otus-reddit:1.0 bash
root@96aba478ca67:/# ps ax | grep start
   16 pts/0    S+     0:00 grep --color=auto start
```
#### Полная информация об образе
```
docker inspect vladimirdenisov69/otus-reddit:1.0 

docker inspect vladimirdenisov69/otus-reddit:1.0 -f '{{.ContainerConfig.Cmd}}'
[/bin/sh -c #(nop)  CMD ["/start.sh"]]
```

#### Вывод списка измененных файлов и каталогов в контейнере
```docker diff reddit```

## 13.2.2 Настройка infra. Подготовительные действия - создание ssh ключей и сервисного аккаунта в GCP
```
export REPO_PATH=$(pwd)
export GCP_PROJECT=docker-project-name-here
ssh-keygen -t rsa -f ~/.ssh/docker-user -C 'docker-user' -q -N ''

gcloud iam service-accounts create docker-user --display-name docker-user

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --member serviceAccount:docker-user@"${GCP_PROJECT}".iam.gserviceaccount.com --role roles/editor
```
## 13.2.2 Настройка infra. Создание образа docker-host-base с помощью packer
 Создание образа хоста с предустановленным docker engine
```
cd "${REPO_PATH}"/docker-monolith/infra
packer build -var-file=packer/variables.json packer/docker_host.json
```
## 13.2.3 Настройка infra. Создание инстансов docker host через Terraform
```cd "${REPO_PATH}"/docker-monolith/infra/terraform```
 Перед выполением команд нужно настроить terrafrom.tfvars файл для создания remote backend
```
terraform init
terraform apply

cd "${REPO_PATH}"/stage
```
Перед выполением команд нужно настроить terrafrom.tfvars файл для создания инстансов docker host и правил файерволла
```
terraform init
terrafrom apply
```
## 13.2.2 Настройка infra. Запуск reddit app
```cd "${REPO_PATH}"/docker-monolith/infra/ansible```
 - Скопировать файл с секретными данными от service account
```
gcloud iam service-accounts keys create environments/stage/gce-service-account.json --iam-account docker-user@"${GCP_PROJECT}".iam.gserviceaccount.com
```
 - Настроить gce dynamic inventory
```ansible-playbook playbooks/gce_dynamic_inventory_setup.yml```

 - Развернуть reddit app на инстансах созданных ранее, через terraform
```ansible-playbook playbooks/site.yml```
## 13.3 Как проверить проект
Приложение будет доступно в веб-браузере по адресу http://ip_address:9292, где список ip_address можно узнать командами
Получить список всех ip адресов
```
cd "${REPO_PATH}"/docker-monolith/infra/terraform/stage
terraform output
```
## Домашнее задание №12 - docker-1

Образ, это статичный объект, для него отсутствует такое понятие, как состояние ("State"). 
Образ предназначен для разворачивания и выполнения среды внутри контейнера, соответственно, содержит в себе базовый образ ОС ("Image": "ubuntu:16.04"), архитектуру ("Architecture": "amd64"), слои из которых состоит образ (см.ниже).
Контейнер, это среда выполнения ОС и установленного ПО, загружаемая из образа. 
Контейнер имеет состояние выполнения, для него определены уникальные настройки сети, загружены необходимые драйвера, выделено определенное количество вычислительных ресурсов.

Docker image состоит из набора read-only слоев, например
```
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:0a42ee6ceccb1b90de2a3badec7c74cc452ce61e7ef20a80bb7f20ea53f2825e",
                "sha256:c2af38e6b250a39e0e7b9665687385c75fdf7bab5ea856a2eec4fd6b74adda95",
                "sha256:5e95929b27983df137a6cff59695739f69f6571e70fa68eb6a7abe3b74e402d2",
                "sha256:2166dba7c95bfbc84b38b7a6c7d96d323d16239aeff2f2292c61821002df2dfb",
                "sha256:bcff331e13e35a0beb71d43b4f6b859327f18587f084a1036a603e64a990e44d",
                "sha256:75c8539bf147fe1f8b86f55a683b1c8126b78307fed51675d675eb789a6acfed"
            ]
        },
```
Каждый слой - это diff от предыдущего слоя. 
Разные images могут использовать общие слои - кешируются (не нужно загружать каждый слой каждый раз если он уже есть).

Про контейнеры.

Создание нового контейнера создает COW read/write слой поверх image, этот слой называется container layer.
В нем отличие контейнера от image (когда удаляется контейнер, то удаляется только его r/w слой, нижележащий image остается)
При записи в файл контейнер просматривает слои (сверху-вниз, от самого нового, до самого старого).
Файл копируется в writable слой и вся запись происходит в этот скопированный файл при этом контейнер не видит нижележащие read-only копии этого файла.
В контейнерах есть состояние связанное с его runtime, описание сетевых интерфейсов, например
```
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
...
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
```

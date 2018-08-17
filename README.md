# VladimirDe_microservices
VladimirDe microservices repository

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

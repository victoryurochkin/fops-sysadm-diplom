# Курсовая работа по профессии «DevOps-инженер с нуля»

### Отказоустойчивая инфраструктура веб-приложения с мониторингом, централизованным логированием и резервным копированием - https://github.com/netology-code/fops-sysadm-diplom/blob/main/README.md

#### Автор: Юрочкин Виктор Алексеевич
#### Курс: "DevOps-инженер с нуля" (FOPS-41)

---

#### Оглавление

1. Введение
2. Цели и задачи проекта
3. Архитектура инфраструктуры, схема
4. Аппаратная платформа
5. Виртуальная инфраструктура
6. Сетевая топология
7. Внешний Web Application Firewall (BunkerWeb)
8. Балансировщик нагрузки (Nginx)
9. Бэкенд-серверы приложения
10. Система мониторинга (Zabbix)
11. Централизованный сбор логов (ELK Stack)
12. Агент логирования Filebeat
13. Наблюдаемость инфраструктуры (Observability)
14. Меры безопасности инфраструктуры
15. CI/CD пайплайн (пример реализации)
16. Infrastructure as Code (Terraform – пример)
17. Автоматизация развертывания с помощью Ansible
18. Интеграционное тестирование инфраструктуры
19. Стратегия резервного копирования
20. Итоговая архитектурная схема
21. Заключение

---

**1. Введение**

Современные веб-проекты требуют не только развертывания приложения, но и создания полноценной эксплуатационной инфраструктуры, обеспечивающей:

- отказоустойчивость;
- защиту от сетевых атак;
- централизованный мониторинг;
- сбор и анализ логов;
- автоматизацию инфраструктуры;
- резервное копирование данных.
   
**Целью данной работы является разработка и реализация отказоустойчивой инфраструктуры для веб-сайта:**

`victoryur.tech` - https://victoryur.tech

**Инфраструктура включает следующие ключевые компоненты:**

- внешний Web Application Firewall (WAF);
- балансировщик нагрузки;
- несколько бэкенд-серверов приложения;
- систему мониторинга;
- систему централизованного логирования;
- систему резервного копирования;
- возможность автоматизации развертывания.

В отличие от типичных решений, использующих облачные платформы (AWS, Yandex Cloud), данная инфраструктура построена полностью на собственных физических ресурсах с использованием гипервизора Proxmox VE. Это позволяет детально изучить все аспекты сетевого взаимодействия, настройки сервисов и их интеграции без абстракций, создаваемых облачными провайдерами.

---

#### 2. Цели и задачи проекта

**Основная цель**

Спроектировать и реализовать **отказоустойчивую, безопасную и наблюдаемую инфраструктуру для размещения веб-сайта**.

**Для реализации используются следующие технологии:**

- BunkerWeb — Web Application Firewall
- Nginx — балансировка нагрузки
- Ubuntu Server / Debian — серверные операционные системы
- Zabbix — система мониторинга
- Elasticsearch + Kibana — система анализа логов
- Filebeat — агент передачи логов
- Proxmox VE — виртуализация
- OPNSense — сетевой экран и маршрутизация

**Задачи**

1. Развернуть гипервизор Proxmox VE и создать виртуальные машины согласно архитектуре.
2. Настроить OPNSense для проброса портов и защиты периметра.
3. Установить и настроить WAF (BunkerWeb) для фильтрации входящего трафика.
4. Сконфигурировать балансировщик Nginx для распределения нагрузки между двумя бэкендами.
5. Подготовить два идентичных бэкенд-сервера с веб-сервером Nginx и тестовой страницей.
6. Развернуть сервер мониторинга Zabbix и установить агенты на все узлы.
7. Развернуть стек ELK (Elasticsearch + Kibana) и настроить Filebeat для отправки логов с бэкендов.
8. Организовать резервное копирование виртуальных машин средствами Proxmox.
9. Провести интеграционное тестирование, включая сценарии отказа.
10. Подготовить плейбуки Ansible для автоматизации развертывания.

---

#### 3. Архитектура инфраструктуры, схема

Инфраструктура состоит из нескольких логических уровней:

<img width="398" height="910" alt="image" src="https://github.com/user-attachments/assets/d24b0071-f82e-4d01-935d-997a7542d951" />

---

#### 5. Аппаратная платформа

Вся инфраструктура размещена на физическом сервере.

| Параметр      | Значение               |
|---------------|------------------------|
| Hostname      | pve100                 |
| Гипервизор    | Proxmox VE 9.1.6       |
| IP            | 192.168.1.100          |

---

#### 6. Виртуальная инфраструктура

| VM ID   | Hostname              | IP           | ОС           | Роль                       |
|---------|-----------------------|--------------|--------------|----------------------------|
| 10000   | bunker.victoryur.tech | 192.168.1.10 | Ubuntu 22.04 | WAF (BunkerWeb)            |
| 10001   | z.victoryur.tech      | 192.168.1.83 | Debian 12    | Zabbix Server              |
| 10002   | victoryur.tech-88     | 192.168.1.88 | Ubuntu 22.04 | Backend №1                 |
| 10003   | victoryur.tech-89     | 192.168.1.89 | Ubuntu 22.04 | Backend №2                 |
| 11111   | balancer              | 192.168.1.90 | Ubuntu 22.04 | Load Balancer (Nginx)      |
| 22222   | elk                   | 192.168.1.31 | Ubuntu 22.04 | Elasticsearch + Kibana     |


<img width="1919" height="892" alt="image" src="https://github.com/user-attachments/assets/1ede7ac9-5d31-406d-a23e-f2d2e61c44de" />

---

#### 7. Сетевая топология

```
Интернет
   │
   ▼
OPNSense (WAN: 109.74.128.125, LAN: 192.168.1.1)
   │ DNAT 80/443 → 192.168.1.10
   ▼
BunkerWeb WAF (192.168.1.10)
   │
   ├── victoryur.tech → Balancer (192.168.1.90)
   │                     │
   │                     ├── Backend 1 (192.168.1.88)  → Zabbix Agent, Filebeat
   │                     └── Backend 2 (192.168.1.89)  → Zabbix Agent, Filebeat
   │
   └── z.victoryur.tech → Zabbix Server (192.168.1.83) + MariaDB

Backends → Elasticsearch (192.168.1.31:9200)
Backends → Zabbix Server (192.168.1.83:10050)
Администратор → Kibana (192.168.1.31:5601) через SSH-туннель
```

---

#### 8. Внешний Web Application Firewall (BunkerWeb)

**WAF развернут на сервере Ubuntu 22.04 с использованием Docker.**

**Установка Docker**

```
apt update && apt upgrade -y
curl -fsSL https://get.docker.com | sh
systemctl enable docker --now
```

**Запуск контейнера**

```
docker run -d \
  --name bunkerweb \
  -p 80:8080 \
  -p 443:8443 \
  bunkerity/bunkerweb-all-in-one:1.6.7
```

**BunkerWeb обеспечивает:**

- защиту от SQL-инъекций;
- защиту от XSS-атак;
- фильтрацию HTTP-запросов;
- ограничение частоты запросов (rate limiting).

<img width="1919" height="1086" alt="image" src="https://github.com/user-attachments/assets/9f25e599-6b35-4365-a064-297163790b95" />


**Настроены правила проксирования:**

`victoryur.tech → http://192.168.1.90:80`

<img width="1919" height="1092" alt="image" src="https://github.com/user-attachments/assets/9c373645-63b6-47d9-b54d-00d096a2ec9d" />

---

#### 9. Балансировщик нагрузки (Nginx)
Балансировка трафика выполняется сервером Nginx на ВМ `balancer`.

**Конфигурация upstream**

```
upstream victoryur_backend {
    least_conn;
    server 192.168.1.88:80 max_fails=2 fail_timeout=5s;
    server 192.168.1.89:80 max_fails=2 fail_timeout=5s;
    keepalive 32;
}
```

Алгоритм балансировки: **least_conn**. Добавлены параметры для автоматического исключения отказавшего сервера.

Виртуальные хосты
Для корректной обработки запросов как по домену, так и по IP, настроены три серверных блока (полная конфигурация приведена в приложении).

---

#### 10. Бэкенд-серверы

**Каждый backend-сервер содержит:**

- веб-сервер Nginx;
- тестовую страницу сайта;
- агент мониторинга Zabbix;
- агент логирования Filebeat.

Для тестирования балансировки используется файл `.node`, содержащий имя сервера (`web01` или `web02`).

Конфигурация Nginx на бэкенде:

```
server {
    listen 80;
    server_name victoryur.tech www.victoryur.tech;
    root /var/www/victoryur.tech/public;
    index index.html;
    access_log /var/log/nginx/victoryur.tech.access.log;
    error_log  /var/log/nginx/victoryur.tech.error.log;
    location / {
        try_files $uri $uri/ =404;
    }
    location = /health {
        access_log off;
        return 200 "OK\n";
    }
}
```

Ограничение доступа: разрешён только IP балансировщика (192.168.1.90).

---

#### 11. Система мониторинга (Zabbix)

**Мониторинг реализован с помощью Zabbix 7.0 на сервере Debian 12.**

**Компоненты**

| Компонент     | Назначение                  |
|---------------|-----------------------------|
| Zabbix Server | сбор и хранение метрик      |
| MariaDB       | база данных                 |
| Zabbix Agent  | агент мониторинга на узлах  |

**Отслеживаемые метрики**

- загрузка CPU;
- использование памяти;
- сетевой трафик;
- использование диска;
- uptime.

<img width="1919" height="1093" alt="image" src="https://github.com/user-attachments/assets/3795c4d0-ad8a-4a8a-8cc4-29f394f67234" />

---

#### 12. Централизованный сбор логов (ELK Stack)

Для анализа логов используется стек:

- Elasticsearch (хранение и поиск);
- Kibana (визуализация).

Elasticsearch работает на порту 9200 (HTTPS). Для корректной работы изменён параметр ядра:

```
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p
```

<img width="1917" height="1087" alt="image" src="https://github.com/user-attachments/assets/e246447c-f516-40a5-92b9-488842de2988" />

<img width="1919" height="1090" alt="image" src="https://github.com/user-attachments/assets/c3e62169-a54a-4fac-bfa3-313545bfb5e9" />

---

#### 13. Агент логирования Filebeat

**Filebeat установлен на backend-серверах.**

**Пример конфигурации:**

```
output.elasticsearch:
  hosts: ["https://192.168.1.31:9200"]
  username: "elastic"
  password: "*B9=5+iuJwaD2Ivt8=fq"
  ssl.certificate_authorities: ["/etc/filebeat/http_ca.crt"]
```

**Передаются логи:**

- `/var/log/nginx/access.log`

- `/var/log/nginx/error.log`

---

#### 14. Наблюдаемость инфраструктуры (Observability)

**Наблюдаемость реализована через:**

- Zabbix — метрики системы (CPU, память, диск, сеть);
- ELK — анализ логов;
- Kibana — визуализация и построение дашбордов.

**Это позволяет выявлять:**

- сетевые аномалии;
- падения серверов;
- деградацию производительности;
- ошибки приложения.

---

#### 15. Меры безопасности инфраструктуры

**В инфраструктуре реализованы следующие меры безопасности:**


|Уровень	       |Мера
|---------------|--------------------------------------------------------------------|
|Сеть	          | OPNSense – межсетевой экран, NAT, фильтрация                       |
|Веб-трафик	    | BunkerWeb WAF (OWASP Core Rule Set)                                |
|Доступ по SSH	 | только по ключам, отдельный пользователь inspector                 |
|Сегментация	 | внутренняя подсеть 192.168.1.0/24, доступ извне только через WAF   |
|Логирование	 | централизованный сбор логов для аудита                             |
|Обновления	    | регулярное обновление ОС и пакетов                                 |

---

#### 16. CI/CD пайплайн (пример реализации)

**Для автоматизации деплоя приложения можно использовать GitHub Actions.**

Пример `.github/workflows/deploy.yml:`

```
name: Deploy

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install SSH key
        uses: webfactory/ssh-agent@v0.5.4
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Run Ansible playbook
        run: |
          cd ansible
          ansible-playbook -i inventory/production.yml playbooks/deploy.yml
```

---

#### 17. Infrastructure as Code (Terraform – пример)

**Для управления виртуальными машинами в Proxmox можно использовать Terraform.**

Пример `main.tf:`

```
provider "proxmox" {
  pm_api_url = "https://192.168.1.100:8006/api2/json"
  pm_user    = "root@pam"
  pm_password = var.pm_password
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "web01" {
  name        = "web01"
  target_node = "pve100"
  clone       = "ubuntu-22.04-template"
  cores       = 2
  memory      = 2048
  disk {
    size    = "20G"
    storage = "local-lvm"
  }
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  ipconfig0 = "ip=192.168.1.88/24,gw=192.168.1.1"
}
```
---

#### 18. Автоматизация развертывания с помощью Ansible

Для воспроизводимого развертывания конфигурации всех сервисов разработан набор Ansible-плейбуков и ролей.

**Структура репозитория Ansible**

```
ansible/
├── inventory/
│   └── production.yml
├── group_vars/
│   └── all.yml
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
├── roles/
│   ├── common/
│   │   └── tasks/
│   │       └── main.yml
│   ├── waf/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── templates/
│   │       └── docker-compose.yml.j2
│   ├── nginx/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── templates/
│   │       └── nginx-balancer.conf.j2
│   ├── backend/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── templates/
│   │       ├── nginx-backend.conf.j2
│   │       └── index.html.j2
│   ├── zabbix/
│   │   ├── tasks/
│   │   │   ├── server.yml
│   │   │   └── agent.yml
│   │   └── templates/
│   │       └── zabbix_agentd.conf.j2
│   └── elk/
│       ├── tasks/
│       │   ├── elasticsearch.yml
│       │   ├── kibana.yml
│       │   └── filebeat.yml
│       └── templates/
│           └── filebeat.yml.j2

```

**Инвентарный файл** `inventory/production.yml`

```
all:
  children:
    waf:
      hosts:
        bunker:
          ansible_host: 192.168.1.10
    balancer:
      hosts:
        balancer:
          ansible_host: 192.168.1.90
    backend:
      hosts:
        web01:
          ansible_host: 192.168.1.88
        web02:
          ansible_host: 192.168.1.89
    zabbix:
      hosts:
        zabbix:
          ansible_host: 192.168.1.83
    elk:
      hosts:
        elk:
          ansible_host: 192.168.1.31
  vars:
    ansible_user: root
```

**Групповые переменные** `group_vars/all.yml`

```
domain: victoryur.tech
zabbix_server_ip: 192.168.1.83
elasticsearch_host: 192.168.1.31
elasticsearch_port: 9200
```

**Основной плейбук** `playbooks/site.yml`

```
- hosts: all
  become: yes
  roles:
    - common

- hosts: waf
  become: yes
  roles:
    - waf

- hosts: balancer
  become: yes
  roles:
    - nginx

- hosts: backend
  become: yes
  roles:
    - backend
    - zabbix
    - elk

- hosts: zabbix
  become: yes
  roles:
    - zabbix

- hosts: elk
  become: yes
  roles:
    - elk
```

**Примеры содержимого ролей**

**Роль** `common/tasks/main.yml`

```
- name: install base packages
  apt:
    name:
      - curl
      - vim
      - git
      - htop
      - net-tools
    update_cache: yes
```

**Роль** `waf/tasks/main.yml`

```
- name: install docker
  apt:
    name:
      - docker.io
      - docker-compose
    state: present
    update_cache: yes

- name: enable docker
  systemd:
    name: docker
    state: started
    enabled: yes

- name: create directory
  file:
    path: /opt/bunkerweb
    state: directory

- name: copy docker compose
  template:
    src: docker-compose.yml.j2
    dest: /opt/bunkerweb/docker-compose.yml

- name: start bunkerweb
  command: docker compose up -d
  args:
    chdir: /opt/bunkerweb
```

**Шаблон** `waf/templates/docker-compose.yml.j2:`

```
version: '3'
services:
  bunkerweb:
    image: bunkerity/bunkerweb-all-in-one:1.6.7
    ports:
      - "80:8080"
      - "443:8443"
    restart: always
    environment:
      - SERVER_NAME={{ domain }}
      - USE_REVERSE_PROXY=yes
      - REVERSE_PROXY_HOST_1=http://192.168.1.90
```

**Роль** `nginx/tasks/main.yml`

```
- name: install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: configure nginx
  template:
    src: nginx-balancer.conf.j2
    dest: /etc/nginx/sites-available/default

- name: restart nginx
  service:
    name: nginx
    state: restarted
```

**Шаблон** `nginx/templates/nginx-balancer.conf.j2:`

```
upstream backend_cluster {
    least_conn;
    server 192.168.1.88:80;
    server 192.168.1.89:80;
    keepalive 32;
}

server {
    listen 80;
    server_name {{ domain }};
    location / {
        proxy_pass http://backend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**Роль** `backend/tasks/main.yml`

```
- name: install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: copy nginx config
  template:
    src: nginx-backend.conf.j2
    dest: /etc/nginx/sites-available/default

- name: create test page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html

- name: create node file
  copy:
    content: "{{ inventory_hostname }}"
    dest: /var/www/html/.node

- name: restart nginx
  service:
    name: nginx
    state: restarted
```

**Шаблон** `backend/templates/nginx-backend.conf.j2:`

```
server {
    listen 80;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

**Шаблон** `backend/templates/index.html.j2:`

```
<html>
<head><title>{{ inventory_hostname }}</title></head>
<body><h1>{{ inventory_hostname }}</h1></body>
</html>
```

**Роль** `zabbix/tasks/agent.yml`

```
- name: install zabbix agent
  apt:
    name: zabbix-agent
    state: present
    update_cache: yes

- name: configure agent
  template:
    src: zabbix_agentd.conf.j2
    dest: /etc/zabbix/zabbix_agentd.conf

- name: restart agent
  service:
    name: zabbix-agent
    state: restarted
```

**Шаблон** `zabbix/templates/zabbix_agentd.conf.j2:`

```
Server={{ zabbix_server_ip }}
ServerActive={{ zabbix_server_ip }}
Hostname={{ inventory_hostname }}
```

**Роль** `elk/tasks/elasticsearch.yml`

```
- name: install elasticsearch
  apt:
    name: elasticsearch
    state: present
    update_cache: yes

- name: start elasticsearch
  service:
    name: elasticsearch
    state: started
```

**Роль** `elk/tasks/kibana.yml`

```
- name: install kibana
  apt:
    name: kibana
    state: present

- name: start kibana
  service:
    name: kibana
    state: started
```

**Роль** `elk/tasks/filebeat.yml`

```
- name: install filebeat
  apt:
    name: filebeat
    state: present
    update_cache: yes

- name: configure filebeat
  template:
    src: filebeat.yml.j2
    dest: /etc/filebeat/filebeat.yml

- name: start filebeat
  service:
    name: filebeat
    state: restarted
```

**Шаблон** `elk/templates/filebeat.yml.j2:`

```
filebeat.inputs:
- type: log
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log
output.elasticsearch:
  hosts: ["http://{{ elasticsearch_host }}:{{ elasticsearch_port }}"]
```

**Запуск развертывания**

```
ansible-playbook -i inventory/production.yml playbooks/site.yml
```

---

#### 19. Интеграционное тестирование инфраструктуры

**Проверка балансировки в штатном режиме**

```
for i in {1..10}; do curl -s http://victoryur.tech/.node; done
```

Ожидаемый результат (пример):

```
web01
web02
web01
web02
...
```

<img width="990" height="510" alt="image" src="https://github.com/user-attachments/assets/aed669ae-c801-4f0b-9a22-fd8cbcc07616" />


**Проверка отказоустойчивости**

Имитация отказа web01:

```
ssh it@192.168.1.88 "sudo systemctl stop nginx"
```

Повторный запуск цикла запросов – все ответы должны идти от `web02`. После восстановления балансировка возвращается.

Проверка логирования
Создание тестовых запросов и проверка появления записей в Kibana.

Проверка мониторинга
В веб-интерфейсе Zabbix должны отображаться графики для всех узлов.

---

#### 20. Стратегия резервного копирования

Резервное копирование реализовано средствами Proxmox VE.


|Параметр	|Значение
|-----------|----------------------------------|
|Расписание	|ежедневно в 21:00                 |
|Хранение	|keep-last=2 (2 последние копии)   |
|Хранилище	|Backups (локальное)               |

Резервируются все виртуальные машины (10000, 10001, 10002, 10003, 11111, 22222). В случае сбоя восстановление выполняется через веб-интерфейс Proxmox выбором нужной копии.

<img width="1918" height="392" alt="image" src="https://github.com/user-attachments/assets/a4264634-e296-4fc7-8948-cff2db0a49b9" />


<img width="1917" height="562" alt="image" src="https://github.com/user-attachments/assets/b46a1069-6559-4dc7-b4e3-8503e8689cf1" />

---

#### 21. Итоговая архитектурная схема

```
Интернет
   │
   ▼
OPNSense (WAN: 109.74.128.125, LAN: 192.168.1.1)
   │ DNAT 80/443 → 192.168.1.10
   ▼
BunkerWeb WAF (192.168.1.10)
   │
   ├── victoryur.tech → Balancer (192.168.1.90)
   │                     │
   │                     ├── Backend 1 (192.168.1.88)  → Zabbix Agent, Filebeat
   │                     └── Backend 2 (192.168.1.89)  → Zabbix Agent, Filebeat
   │
   └── z.victoryur.tech → Zabbix Server (192.168.1.83) + MariaDB

Backends → Elasticsearch (192.168.1.31:9200)
Backends → Zabbix Server (192.168.1.83:10050)
Администратор → Kibana (192.168.1.31:5601) через SSH-туннель
```

#### 22. Заключение

В рамках проекта была реализована полноценная отказоустойчивая инфраструктура для веб-приложения.

**Реализованы следующие компоненты:**

- Web Application Firewall (BunkerWeb) для защиты от атак;
- балансировка нагрузки (Nginx) с методом least_conn;
- дублирование backend-серверов для отказоустойчивости;
- централизованный мониторинг (Zabbix) всех узлов;
- централизованный сбор логов (ELK Stack) с визуализацией в Kibana;
- резервное копирование инфраструктуры средствами Proxmox;
- автоматизация развертывания с помощью Ansible.
- Инфраструктура способна продолжать работу при отказе одного из backend-серверов, а также обеспечивает полный контроль состояния системы и анализ логов. Все поставленные задачи проекта выполнены.

Разработанные Ansible-плейбулы позволяют воспроизвести конфигурацию в любой среде, что делает проект готовым к промышленной эксплуатации.


---

#!/bin/bash

set -e

# Устанавливаем Ansible
echo "Устанавливаем Ansible..."
apt update && apt install -y ansible git vim curl

# Создаём структуру директорий
echo "Создаём структуру репозитория Ansible..."
mkdir -p ansible/{inventory,group_vars,playbooks,roles/{common,waf/nginx,backend,zabbix,elk}/{tasks,templates}}

# ------------------------
# Inventory
cat > ansible/inventory/production.yml <<'EOF'
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
EOF

# ------------------------
# Group Vars
cat > ansible/group_vars/all.yml <<'EOF'
domain: victoryur.tech
zabbix_server_ip: 192.168.1.83
elasticsearch_host: 192.168.1.31
elasticsearch_port: 9200
EOF

# ------------------------
# Playbooks
cat > ansible/playbooks/site.yml <<'EOF'
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
EOF

cat > ansible/playbooks/deploy.yml <<'EOF'
- hosts: all
  become: yes
  roles:
    - common
EOF

# ------------------------
# Roles: common
cat > ansible/roles/common/tasks/main.yml <<'EOF'
- name: install base packages
  apt:
    name:
      - curl
      - vim
      - git
      - htop
      - net-tools
    update_cache: yes
EOF

# ------------------------
# Roles: waf
cat > ansible/roles/waf/tasks/main.yml <<'EOF'
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
EOF

cat > ansible/roles/waf/templates/docker-compose.yml.j2 <<'EOF'
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
EOF

# ------------------------
# Roles: nginx
cat > ansible/roles/nginx/tasks/main.yml <<'EOF'
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
EOF

cat > ansible/roles/nginx/templates/nginx-balancer.conf.j2 <<'EOF'
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
EOF

# ------------------------
# Roles: backend
cat > ansible/roles/backend/tasks/main.yml <<'EOF'
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
EOF

cat > ansible/roles/backend/templates/nginx-backend.conf.j2 <<'EOF'
server {
    listen 80;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

cat > ansible/roles/backend/templates/index.html.j2 <<'EOF'
<html>
<head><title>{{ inventory_hostname }}</title></head>
<body><h1>{{ inventory_hostname }}</h1></body>
</html>
EOF

# ------------------------
# Roles: zabbix
cat > ansible/roles/zabbix/tasks/agent.yml <<'EOF'
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
EOF

cat > ansible/roles/zabbix/templates/zabbix_agentd.conf.j2 <<'EOF'
Server={{ zabbix_server_ip }}
ServerActive={{ zabbix_server_ip }}
Hostname={{ inventory_hostname }}
EOF

# ------------------------
# Roles: elk
cat > ansible/roles/elk/tasks/elasticsearch.yml <<'EOF'
- name: install elasticsearch
  apt:
    name: elasticsearch
    state: present
    update_cache: yes

- name: start elasticsearch
  service:
    name: elasticsearch
    state: started
EOF

cat > ansible/roles/elk/tasks/kibana.yml <<'EOF'
- name: install kibana
  apt:
    name: kibana
    state: present

- name: start kibana
  service:
    name: kibana
    state: started
EOF

cat > ansible/roles/elk/tasks/filebeat.yml <<'EOF'
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
EOF

cat > ansible/roles/elk/templates/filebeat.yml.j2 <<'EOF'
filebeat.inputs:
- type: log
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log
output.elasticsearch:
  hosts: ["http://{{ elasticsearch_host }}:{{ elasticsearch_port }}"]
EOF

echo "Структура Ansible успешно создана в папке ansible/"

#!/bin/bash

if [[ $(id -u) != "0" ]]; then
    echo -e "\e[0;31m"Error: You must be root to run this install script."\e[0m"
    exit 1
fi

basepath=$(dirname $0)
cd ${basepath}

INSTALL_PANNEL_Env() {
     echo -e "\e[0;36m"Installing Pannel Environment..."\e[0m"
    apt install python3 python3-pip virtualenv build-essential python3-dev nginx git uwsgi-plugin-python3 -y
    if [    "$?" = "0" ];then
        echo -e "\e[0;32m"Environment Installation Was Successful."\e[0m"
    else
        echo -e "\e[0;31m"Environment Installation Is Failed"\e[0m"
        exit 1
    fi
}

GIT_PROJECT(){
    echo -e "\e[0;36m"Get Project From Git Repository..."\e[0m"
    git clone https://github.com/mmtaee/Ocserv-Vpn-User-Management.git
    if [    "$?" = "0" ];then
        echo -e "\e[0;32m"Git Clone Was Successful."\e[0m"
    else
        echo -e "\e[0;31m"Cannot "Git Clone" Project From "github"."\e[0m"
        exit 1
    fi
}

PRO_DIR() {
    echo -e "\e[0;36m"Preparation Directorys And Files..."\e[0m"

    mkdir /var/www/html/ocserv_pannel/

    cp -r $(pwd)/* /var/www/html/ocserv_pannel/
}

PRO_VENV() {
    echo -e "\e[0;36m"Creating Python virtualenv..."\e[0m"

    cd /var/www/html/ocserv_pannel/

    virtualenv -p python3 venv

    source venv/bin/activate

    pip install -r requirements.txt

    ./manage.py migrate

    echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@myproject.com', 'admin')" | python manage.py shell

    mkdir static

    echo -e yes\n |./manage.py collectstatic

    chown -R www-data /var/www/html/ocserv_pannel/

    echo www-data ALL = NOPASSWD: /usr/local/bin/ocpasswd >> /etc/sudoers

    echo www-data ALL = NOPASSWD: /usr/local/bin/occtl >> /etc/sudoers
    
    echo www-data ALL = NOPASSWD: /usr/bin/systemctl restart ocserv.service >> /etc/sudoers
    
    echo www-data ALL = NOPASSWD: /usr/bin/systemctl status ocserv.service >> /etc/sudoers
}

PRO_SERVICES() {
    echo -e "\e[0;36m"Preparation Nginx"\e[0m"
    #################COPY CONFIG FILE
    rm -rf /etc/nginx/sites-enabled/default
    mv /var/www/html/ocserv_pannel/configs/ocserv_nginx.conf /etc/nginx/conf.d/
    mv /var/www/html/ocserv_pannel/configs/ocserv_uwsgi.service /lib/systemd/system
    systemctl daemon-reload;systemctl restart nginx ocserv_uwsgi.service;systemctl enable nginx ocserv_uwsgi.service;
    NGINX_STATE=`systemctl is-active nginx`
    if [    "$NGINX_STATE" = "active"  ]; then
        echo -e "\e[0;32m"Nginx Is Started."\e[0m"
    else
        echo -e "\e[0;31m"Nginx Is Not Running."\e[0m"
        exit 1
    fi
    OCSERV_STATE=`systemctl is-active ocserv`
    if [    "$OCSERV_STATE" = "active"  ]; then
        echo -e "\e[0;32m"Ocserv Is Started."\e[0m"
    else
        echo -e "\e[0;31m"Ocserv Is Not Running."\e[0m"
        exit 1
    fi  
        OCSERV_UWSGI_STATE=`systemctl is-active ocserv_uwsgi`
    if [    "$OCSERV_UWSGI_STATE" = "active"   ]; then
        echo -e "\e[0;32m"Ocserv_Uwsgi Is Started."\e[0m"
    else
        echo -e "\e[0;31m"Ocserv_Uwsgi Is Not Running."\e[0m"
        exit 1
    fi        
    
}

INSTALL_PANNEL_Env
PRO_DIR
PRO_VENV
PRO_SERVICES

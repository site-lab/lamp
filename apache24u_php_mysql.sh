#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4.x+php7+MySQLのインストール
・apache2.4.x
・mod_sslのインストール
・PHP7系のインストール
・MySQLのインストール
・centosユーザーの作成

COMMENT


start_message(){
echo ""
echo "======================開始======================"
echo ""
}

end_message(){
echo ""
echo "======================完了======================"
echo ""
}

#CentOS7か確認
if [ -e /etc/redhat-release ]; then
    DIST="redhat"
    DIST_VER=`cat /etc/redhat-release | sed -e "s/.*\s\([0-9]\)\..*/\1/"`
    #DIST_VER=`cat /etc/redhat-release | perl -pe 's/.*release ([0-9.]+) .*/$1/' | cut -d "." -f 1`

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "7" ];then
        #EPELリポジトリのインストール
        start_message
        yum remove -y epel-release
        yum -y install epel-release
        end_message

        #Remiリポジトリのインストール
        start_message
        yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
        end_message

        #IUSリポジトリのインストール
        start_message
        echo "IUSリポジトリをインストールします"
        yum -y install https://centos7.iuscommunity.org/ius-release.rpm
        end_message

        #IUSリポジトリをデフォルトから外す
        start_message
        echo "IUSリポジトリをデフォルトから外します"
        cat >/etc/yum.repos.d/ius.repo <<'EOF'
[ius]
name = IUS for Enterprise Linux 7 - $basearch
baseurl = https://repo.ius.io/7/$basearch/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-debuginfo]
name = IUS for Enterprise Linux 7 - $basearch - Debug
baseurl = https://repo.ius.io/7/$basearch/debug/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-source]
name = IUS for Enterprise Linux 7 - Source
baseurl = https://repo.ius.io/7/src/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7
name=IUS Community Packages for Enterprise Linux 7 - $basearch
#baseurl=https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/$basearch
mirrorlist=https://mirrors.iuscommunity.org/mirrorlist?repo=ius-centos7&arch=$basearch&protocol=http
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
EOF
        end_message

        #gitリポジトリのインストール
        start_message
        yum -y install git
        end_message

        #MariaDBを削除
        start_message
        echo "MariaDBを削除します"
        echo ""
        yum -y remove mariadb-libs
        rm -rf /var/lib/mysql/
        end_message


        # yum updateを実行
        echo "yum updateを実行します"
        echo ""

        start_message
        yum -y update
        end_message

        #Nghttp2のインストール
        start_message
        echo "Nghttp2のインストール"
        yum --enablerepo=epel -y install nghttp2
        end_message

        #mailcapのインストール
        start_message
        echo "mailcapのインストール"
        yum -y install mailcap
        end_message

        # apacheのインストール
        echo "apacheをインストールします"
        echo ""

        start_message
        yum -y --enablerepo=ius install httpd24u
        yum -y install openldap-devel expat-devel
        yum -y --enablerepo=ius install httpd24u-devel httpd24u-mod_ssl

        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

        sed -i -e "151d" /etc/httpd/conf/httpd.conf
        sed -i -e "151i AllowOverride All" /etc/httpd/conf/httpd.conf
        sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
        sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
        sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf

        #SSLの設定変更（http2を有効化）
        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk

        sed -i -e "s|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|" /etc/httpd/conf.modules.d/00-mpm.conf
        sed -i -e "s|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|" /etc/httpd/conf.modules.d/00-mpm.conf

        ls /etc/httpd/conf/
        echo "Apacheのバージョン確認"
        echo ""
        httpd -v
        echo ""
        end_message

        #gzip圧縮の設定
        cat >/etc/httpd/conf.d/gzip.conf <<'EOF'
SetOutputFilter DEFLATE
BrowserMatch ^Mozilla/4 gzip-only-text/html
BrowserMatch ^Mozilla/4\.0[678] no-gzip
BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
SetEnvIfNoCase Request_URI\.(?:gif|jpe?g|png)$ no-gzip dont-vary
Header append Vary User-Agent env=!dont-var
EOF


#PHPの選択
PS3="インストールしたいPHPのバージョンを選んでください > "
ITEM_LIST="PHP7.2 PHP7.3 PHP7.4"

select selection in $ITEM_LIST
do
  if [ $selection = "PHP7.2" ]; then
    # php7系のインストール
    echo "php7.2をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php72 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql phpmyadmin
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break
  elif [ $selection = "PHP7.3" ]; then
    # php7系のインストール
    echo "php7.3をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php73 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql phpmyadmin
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  elif [ $selection = "PHP7.4" ]; then
    # php7系のインストール
    echo "php7.4をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php74 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql phpmyadmin
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  else
    echo "どれかを選択してください"
  fi
done

#PHPの選択
PS4="インストールしたいMySQLのバージョンを選んでください > "
ITEM_LIST="MySQL5.7 MySQL8.0"

select selection in $ITEM_LIST
do
  if [ $selection = "MySQL5.7" ]; then

    #公式リポジトリの追加
    start_message
    yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
    yum info mysql-community-server
    end_message

    #MySQLのインストール
    start_message
    echo "MySQLのインストール"
    echo ""
    yum -y install mysql-community-server
    yum list installed | grep mysql
    end_message

    #バージョン確認
    start_message
    echo "MySQLのバージョン確認"
    echo ""
    mysql --version
    end_message

    #my.cnfの設定を変える
    start_message
    echo "ファイル名をリネーム"
    echo "/etc/my.cnf.default"
    mv /etc/my.cnf /etc/my.cnf.default
    mkdir /var/log/mysql/

    echo "新規ファイルを作成してパスワードを無制限使用に変える"
    cat <<EOF >/etc/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

character-set-server = utf8
default_password_lifetime = 0

#slowクエリの設定
slow_query_log=ON
slow_query_log_file=/var/log/mysql-slow.log
long_query_time=0.01
EOF
    end_message
    break
  elif [ $selection = "MySQL8.0" ]; then

    #公式リポジトリの追加
    start_message
    rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
    yum info mysql-community-server
    end_message

    #MySQLのインストール
    start_message
    echo "MySQLのインストール"
    echo ""
    yum -y install mysql-community-server --enablerepo=mysql80-community
    yum list installed | grep mysql
    end_message

    #バージョン確認
    start_message
    echo "MySQLのバージョン確認"
    echo ""
    mysql --version
    end_message

    #my.cnfの設定を変える
    start_message
    echo "ファイル名をリネーム"
    echo "/etc/my.cnf.default"
    mv /etc/my.cnf /etc/my.cnf.default

    echo "新規ファイルを作成してパスワードを無制限使用に変える"
    cat <<EOF >/etc/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.0/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove the leading "# " to disable binary logging
# Binary logging captures changes between backups and is enabled by
# default. It's default setting is log_bin=binlog
# disable_log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
#
# Remove leading # to revert to previous value for default_authentication_plugin,
# this will increase compatibility with older clients. For background, see:
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin
# default-authentication-plugin=mysql_native_password

datadir=/var/lib/mysql
log-error=/var/log/mysqld.log
socket=/var/lib/mysql/mysql.sock

character-set-server = utf8mb4
collation-server = utf8mb4_bin
default_password_lifetime = 0

#旧式のログインに変更
default_authentication_plugin=mysql_native_password

#slowクエリの設定
slow_query_log=ON
slow_query_log_file=/var/log/mysql-slow.log
long_query_time=0.01
EOF
    end_message

    break
  else
    echo "どれかを選択してください"
  fi
done



        #phpmyadminのファイル修正
        cat >/etc/httpd/conf.d/phpMyAdmin.conf <<'EOF'
        # phpMyAdmin - Web based MySQL browser written in php
        #
        # Allows only localhost by default
        #
        # But allowing phpMyAdmin to anyone other than localhost should be considered
        # dangerous unless properly secured by SSL

        Alias /phpMyAdmin /usr/share/phpMyAdmin
        Alias /phpmyadmin /usr/share/phpMyAdmin

        <Directory /usr/share/phpMyAdmin/>
           AddDefaultCharset UTF-8

           <IfModule mod_authz_core.c>
             # Apache 2.4
             Require all granted
           </IfModule>
           <IfModule !mod_authz_core.c>
             # Apache 2.2
             Order Deny,Allow
             Deny from All
             Allow from 127.0.0.1
             Allow from ::1
           </IfModule>
        </Directory>

        <Directory /usr/share/phpMyAdmin/setup/>
           <IfModule mod_authz_core.c>
             # Apache 2.4
             Require all granted
           </IfModule>
           <IfModule !mod_authz_core.c>
             # Apache 2.2
             Order Deny,Allow
             Deny from All
             Allow from 127.0.0.1
             Allow from ::1
           </IfModule>
        </Directory>

        # These directories do not require access over HTTP - taken from the original
        # phpMyAdmin upstream tarball
        #
        <Directory /usr/share/phpMyAdmin/libraries/>
            Order Deny,Allow
            Deny from All
            Allow from None
        </Directory>

        <Directory /usr/share/phpMyAdmin/setup/lib/>
            Order Deny,Allow
            Deny from All
            Allow from None
        </Directory>

        <Directory /usr/share/phpMyAdmin/setup/frames/>
            Order Deny,Allow
            Deny from All
            Allow from None
        </Directory>

        # This configuration prevents mod_security at phpMyAdmin directories from
        # filtering SQL etc.  This may break your mod_security implementation.
        #
        #<IfModule mod_security.c>
        #    <Directory /usr/share/phpMyAdmin/>
        #        SecRuleInheritance Off
        #    </Directory>
        #</IfModule>
EOF

        #php.iniの設定変更
        start_message
        echo "phpのバージョンを非表示にします"
        echo "sed -i -e s|expose_php = On|expose_php = Off| /etc/php.ini"
        sed -i -e "s|expose_php = On|expose_php = Off|" /etc/php.ini
        echo "phpのタイムゾーンを変更"
        echo "sed -i -e s|;date.timezone =|date.timezone = Asia/Tokyo| /etc/php.ini"
        sed -i -e "s|;date.timezone =|date.timezone = Asia/Tokyo|" /etc/php.ini
        end_message


        # phpinfoの作成
        start_message
        touch /var/www/html/info.php
        echo '<?php phpinfo(); ?>' >> /var/www/html/info.php
        cat /var/www/html/info.php
        end_message

        #ユーザー作成
        start_message
        echo "centosユーザーを作成します"
        USERNAME='centos'
        PASSWORD=$(more /dev/urandom  | tr -d -c '[:alnum:]' | fold -w 10 | head -1)
        #DBrootユーザーのパスワード
        RPASSWORD=$(more /dev/urandom  | tr -dc '12345678abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ,.+\-\!' | fold -w 12 | grep -i [12345678] | grep -i '[,.+\-\!]' | head -n 1)
        #DBuser(centos)パスワード
        UPASSWORD=$(more /dev/urandom  | tr -dc '12345678abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ,.+\-\!' | fold -w 12 | grep -i [12345678] | grep -i '[,.+\-\!]' | head -n 1)


        useradd -m -G apache -s /bin/bash "${USERNAME}"
        echo "${PASSWORD}" | passwd --stdin "${USERNAME}"
        echo "パスワードは"${PASSWORD}"です。"

        #所属グループ表示
        echo "所属グループを表示します"
        getent group apache
        end_message

        #所有者の変更
        start_message
        echo "ドキュメントルートの所有者をcentos、グループをapacheにします"
        chown -R centos:apache /var/www/html
        end_message


        # apacheの起動
        echo "apacheを起動します"
        start_message
        systemctl start httpd.service
        echo "apacheのステータス確認"
        systemctl status httpd.service

        echo "MySQLの起動"
        echo ""
        systemctl start mysqld.service
        systemctl status mysqld.service
        end_message

        #自動起動の設定
        start_message
        systemctl enable httpd
        systemctl enable mysqld.service

        systemctl list-unit-files --type=service | grep httpd
        systemctl list-unit-files --type=service | grep mysqld
        end_message

        #パスワード設定
        start_message
        DB_PASSWORD=$(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
        #sed -i -e "s|#password =|password = '${DB_PASSWORD}'|" /etc/my.cnf
        mysql -u root -p${DB_PASSWORD} --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RPASSWORD}'; flush privileges;"
        echo ${RPASSWORD}

cat <<EOF >/etc/createdb.sql
CREATE DATABASE centos;
CREATE USER 'centos'@'localhost' IDENTIFIED BY '${UPASSWORD}';
GRANT ALL PRIVILEGES ON centos.* TO 'centos'@'localhost';
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user;
EOF
mysql -u root -p${RPASSWORD}  -e "source /etc/createdb.sql"

        end_message

        #ファイルを保存
        cat <<EOF >/etc/my.cnf.d/centos.cnf
[client]
user = centos
password = ${UPASSWORD}
host = localhost
EOF

        systemctl restart mysqld.service

        #ファイルの保存
        start_message
        echo "パスワードなどを保存"
        cat <<EOF >/root/pass.txt
root = ${RPASSWORD}
centos = ${UPASSWORD}
EOF
        end_message



        #firewallのポート許可
        echo "http(80番)とhttps(443番)の許可をしてます"
        start_message
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        echo ""
        echo "保存して有効化"
        echo ""
        firewall-cmd --reload

        echo ""
        echo "設定を表示"
        echo ""
        firewall-cmd --list-all
        end_message

        umask 0002

        cat <<EOF
        http://IPアドレス/info.php
        https://IPアドレス/info.php
        で確認してみてください

        ドキュメントルート(DR)は
        /var/www/html
        となります。

        htaccessはドキュメントルートのみ有効化しています

        有効化の確認

        https://www.logw.jp/server/7452.html
        vi /var/www/html/.htaccess
        -----------------
        AuthType Basic
        AuthName hoge
        Require valid-user
        -----------------

        ダイアログがでればhtaccessが有効かされた状態となります。

        ●HTTP2について
        このApacheはHTTP/2に非対応となります。ApacheでHTTP2を使う場合は2.4.17以降が必要となります。

        ドキュメントルートの所有者：グループは｢root｣になっているため、ユーザー名とグループを変更してください

        ---------------------------------------------
        MySQLについて
        MySQLのポリシーではパスワードは
        "8文字以上＋大文字小文字＋数値＋記号"
        でないといけないみたいです
        ---------------------------------------------

        ドキュメントルートの所有者：centos
        グループ：apache
        になっているため、ユーザー名とグループの変更が必要な場合は変更してください

        -----------------
        phpmyadmin
        http://Iアドレス/phpmyadmin/
        ※パスワードなしログインは禁止となっています。rootのパスワード設定してからログインしてください
        -----------------
        MySQLへのログイン方法
        centosユーザーでログインするには下記コマンドを実行してください
        mysql --defaults-extra-file=/etc/my.cnf.d/centos.cnf
        ---------------------------------------------
        ・slow queryはデフォルトでONとなっています
        ・秒数は0.01秒となります
        ・/root/pass.txtにパスワードが保存されています
        ---------------------------------------------

EOF

        echo "centosユーザーのパスワードは"${PASSWORD}"です。"
        echo "データベースのrootユーザーのパスワードは"${RPASSWORD}"です。"
        echo "データベースのcentosユーザーのパスワードは"${UPASSWORD}"です。"


      else
        echo "CentOS7ではないため、このスクリプトは使えません。このスクリプトのインストール対象はCentOS7です。"
      fi
    fi

else
  echo "このスクリプトのインストール対象はCentOS7です。CentOS7以外は動きません。"
  cat <<EOF
  検証LinuxディストリビューションはDebian・Ubuntu・Fedora・Arch Linux（アーチ・リナックス）となります。
EOF
fi


exec $SHELL -l

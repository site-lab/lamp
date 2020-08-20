#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4.6+php7+MySQLのインストール
・apache2.4
・mod_sslのインストール
・PHP7系のインストール
・MariaDBのインストール
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


        #gitリポジトリのインストール
        start_message
        yum -y install git
        end_message

        # yum updateを実行
        echo "yum updateを実行します"
        echo ""

        start_message
        yum -y update
        end_message

        # apacheのインストール
        echo "apacheをインストールします"
        echo ""

        start_message
        yum -y install httpd
        yum -y install openldap-devel expat-devel
        yum -y install httpd-devel mod_ssl

        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

        sed -i -e "151d" /etc/httpd/conf/httpd.conf
        sed -i -e "151i AllowOverride All" /etc/httpd/conf/httpd.conf
        sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
        sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
        sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf

        #SSLの設定変更
        echo "ファイルのバックアップ"
        echo ""
        cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk

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

  ls /etc/httpd/conf/
  #mariaDBのインストール
  start_message
  echo "MariaDB10.3系をインストールします"
cat >/etc/yum.repos.d/MariaDB.repo <<'EOF'
# MariaDB 10.3 CentOS repository list
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

  yum -y install mariadb-server maradb-client
  yum list installed | grep mariadb

  end_message

  #ディレクトリとファイル作成
  start_message
  mkdir /var/log/mysql/
  rm -rf /etc/my.cnf.d/server.cnf
cat >/etc/my.cnf.d/server.cnf <<'EOF'
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

#
# * Galera-related settings
#

#エラーログ
log_error="/var/log/mysql/mysqld.log"
log_warnings=1

#  Query log
general_log = ON
general_log_file="/var/log/mysql/sql.log"

#  Slow Query log
slow_query_log=1
slow_query_log_file="/var/log/mysql/slow.log"
log_queries_not_using_indexes
log_slow_admin_statements
long_query_time=5
character-set-server = utf8


[galera]
# Mandatory settings
#wsrep_on=ON
#wsrep_provider=
#wsrep_cluster_address=
#binlog_format=row
#default_storage_engine=InnoDB
#innodb_autoinc_lock_mode=2
#
# Allow server to accept connections on all interfaces.
#
#bind-address=0.0.0.0
#
# Optional setting
#wsrep_slave_threads=1
#innodb_flush_log_at_trx_commit=0

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.3 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.3]
EOF

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
        systemctl start mariadb.service
        systemctl status mariadb.service
        end_message

        #自動起動の設定
        start_message
        systemctl enable httpd
        systemctl enable mariadb.service

        systemctl list-unit-files --type=service | grep httpd
        systemctl list-unit-files --type=service | grep mariadb
        end_message

        #パスワード設定
        start_message
        DB_PASSWORD=$(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
        #sed -i -e "s|#password =|password = '${DB_PASSWORD}'|" /etc/my.cnf
        mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RPASSWORD}'; flush privileges;"
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
ログインユーザー
centos = ${PASSWORD}
データベース
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

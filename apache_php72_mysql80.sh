#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。centosユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4.6+php7+MySQL8.0のインストール
・apache2.4
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

        #MariaDBを削除
        start_message
        echo "MariaDBを削除します"
        echo ""
        yum -y remove mariadb-libs
        rm -rf /var/lib/mysql/
        end_message

        #公式リポジトリの追加
        start_message
        rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
        yum info mysql-community-server
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
        mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

        echo "htaccess有効化した状態のconfファイルを作成します"
        echo ""

        cat >/etc/httpd/conf/httpd.conf <<'EOF'
#
# This is the main Apache HTTP server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See <URL:http://httpd.apache.org/docs/2.4/> for detailed information.
# In particular, see
# <URL:http://httpd.apache.org/docs/2.4/mod/directives.html>
# for a discussion of each configuration directive.
#
# Do NOT simply read the instructions in here without understanding
# what they do.  They're here only as hints or reminders.  If you are unsure
# consult the online docs. You have been warned.
#
# Configuration and logfile names: If the filenames you specify for many
# of the server's control files begin with "/" (or "drive:/" for Win32), the
# server will use that explicit path.  If the filenames do *not* begin
# with "/", the value of ServerRoot is prepended -- so 'log/access_log'
# with ServerRoot set to '/www' will be interpreted by the
# server as '/www/log/access_log', where as '/log/access_log' will be
# interpreted as '/log/access_log'.

#
# ServerRoot: The top of the directory tree under which the server's
# configuration, error, and log files are kept.
#
# Do not add a slash at the end of the directory path.  If you point
# ServerRoot at a non-local disk, be sure to specify a local disk on the
# Mutex directive, if file-based mutexes are used.  If you wish to share the
# same ServerRoot for multiple httpd daemons, you will need to change at
# least PidFile.
#
ServerRoot "/etc/httpd"

#
# Listen: Allows you to bind Apache to specific IP addresses and/or
# ports, instead of the default. See also the <VirtualHost>
# directive.
#
# Change this to Listen on specific IP addresses as shown below to
# prevent Apache from glomming onto all bound IP addresses.
#
#Listen 12.34.56.78:80
Listen 80

#
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding `LoadModule' lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Statically compiled modules (those listed by `httpd -l') do not need
# to be loaded here.
#
# Example:
# LoadModule foo_module modules/mod_foo.so
#
Include conf.modules.d/*.conf

#
# If you wish httpd to run as a different user or group, you must run
# httpd as root initially and it will switch.
#
# User/Group: The name (or #number) of the user/group to run httpd as.
# It is usually good practice to create a dedicated user and group for
# running httpd, as with most system services.
#
User apache
Group apache

# 'Main' server configuration
#
# The directives in this section set up the values used by the 'main'
# server, which responds to any requests that aren't handled by a
# <VirtualHost> definition.  These values also provide defaults for
# any <VirtualHost> containers you may define later in the file.
#
# All of these directives may appear inside <VirtualHost> containers,
# in which case these default settings will be overridden for the
# virtual host being defined.
#

#
# ServerAdmin: Your address, where problems with the server should be
# e-mailed.  This address appears on some server-generated pages, such
# as error documents.  e.g. admin@your-domain.com
#
ServerAdmin root@localhost

#
# ServerName gives the name and port that the server uses to identify itself.
# This can often be determined automatically, but we recommend you specify
# it explicitly to prevent problems during startup.
#
# If your host doesn't have a registered DNS name, enter its IP address here.
#
#ServerName www.example.com:80

#
# Deny access to the entirety of your server's filesystem. You must
# explicitly permit access to web content directories in other
# <Directory> blocks below.
#
<Directory />
    AllowOverride none
    Require all denied
</Directory>

#
# Note that from this point forward you must specifically allow
# particular features to be enabled - so if something's not working as
# you might expect, make sure that you have specifically enabled it
# below.
#

#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot "/var/www/html"

#
# Relax access to content within /var/www.
#
<Directory "/var/www">
    AllowOverride None
    # Allow open access:
    Require all granted
</Directory>

# Further relax access to the default document root:
<Directory "/var/www/html">
    #
    # Possible values for the Options directive are "None", "All",
    # or any combination of:
    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
    #
    # Note that "MultiViews" must be named *explicitly* --- "Options All"
    # doesn't give it to you.
    #
    # The Options directive is both complicated and important.  Please see
    # http://httpd.apache.org/docs/2.4/mod/core.html#options
    # for more information.
    #
    Options FollowSymLinks

    #
    # AllowOverride controls what directives may be placed in .htaccess files.
    # It can be "All", "None", or any combination of the keywords:
    #   Options FileInfo AuthConfig Limit
    #
    AllowOverride all

    #
    # Controls who can get stuff from this server.
    #
    Require all granted
</Directory>

#
# DirectoryIndex: sets the file that Apache will serve if a directory
# is requested.
#
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

#
# The following lines prevent .htaccess and .htpasswd files from being
# viewed by Web clients.
#
<Files ".ht*">
    Require all denied
</Files>

#
# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
ErrorLog "logs/error_log"

#
# LogLevel: Control the number of messages logged to the error_log.
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
#
LogLevel warn

<IfModule log_config_module>
    #
    # The following directives define some format nicknames for use with
    # a CustomLog directive (see below).
    #
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      # You need to enable mod_logio.c to use %I and %O
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    #
    # The location and format of the access logfile (Common Logfile Format).
    # If you do not define any access logfiles within a <VirtualHost>
    # container, they will be logged here.  Contrariwise, if you *do*
    # define per-<VirtualHost> access logfiles, transactions will be
    # logged therein and *not* in this file.
    #
    #CustomLog "logs/access_log" common

    #
    # If you prefer a logfile with access, agent, and referer information
    # (Combined Logfile Format) you can use the following directive.
    #
    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>
    #
    # Redirect: Allows you to tell clients about documents that used to
    # exist in your server's namespace, but do not anymore. The client
    # will make a new request for the document at its new location.
    # Example:
    # Redirect permanent /foo http://www.example.com/bar

    #
    # Alias: Maps web paths into filesystem paths and is used to
    # access content that does not live under the DocumentRoot.
    # Example:
    # Alias /webpath /full/filesystem/path
    #
    # If you include a trailing / on /webpath then the server will
    # require it to be present in the URL.  You will also likely
    # need to provide a <Directory> section to allow access to
    # the filesystem path.

    #
    # ScriptAlias: This controls which directories contain server scripts.
    # ScriptAliases are essentially the same as Aliases, except that
    # documents in the target directory are treated as applications and
    # run by the server when requested rather than as documents sent to the
    # client.  The same rules about trailing "/" apply to ScriptAlias
    # directives as to Alias.
    #
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"

</IfModule>

#
# "/var/www/cgi-bin" should be changed to whatever your ScriptAliased
# CGI directory exists, if you have that configured.
#
<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    #
    # TypesConfig points to the file containing the list of mappings from
    # filename extension to MIME-type.
    #
    TypesConfig /etc/mime.types

    #
    # AddType allows you to add to or override the MIME configuration
    # file specified in TypesConfig for specific file types.
    #
    #AddType application/x-gzip .tgz
    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    #
    #AddEncoding x-compress .Z
    #AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz

    #
    # AddHandler allows you to map certain file extensions to "handlers":
    # actions unrelated to filetype. These can be either built into the server
    # or added with the Action directive (see below)
    #
    # To use CGI scripts outside of ScriptAliased directories:
    # (You will also need to add "ExecCGI" to the "Options" directive.)
    #
    #AddHandler cgi-script .cgi

    # For type maps (negotiated resources):
    #AddHandler type-map var

    #
    # Filters allow you to process content before it is sent to the client.
    #
    # To parse .shtml files for server-side includes (SSI):
    # (You will also need to add "Includes" to the "Options" directive.)
    #
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

#
# Specify a default charset for all content served; this enables
# interpretation of all content as UTF-8 by default.  To use the
# default browser choice (ISO-8859-1), or to allow the META tags
# in HTML content to override this choice, comment out this
# directive:
#
#AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    #
    # The mod_mime_magic module allows the server to use various hints from the
    # contents of the file itself to determine its type.  The MIMEMagicFile
    # directive tells the module where the hint definitions are located.
    #
    MIMEMagicFile conf/magic
</IfModule>

#
# Customizable error responses come in three flavors:
# 1) plain text 2) local redirects 3) external redirects
#
# Some examples:
#ErrorDocument 500 "The server made a boo boo."
#ErrorDocument 404 /missing.html
#ErrorDocument 404 "/cgi-bin/missing_handler.pl"
#ErrorDocument 402 http://www.example.com/subscription_info.html
#

#
# EnableMMAP and EnableSendfile: On systems that support it,
# memory-mapping or the sendfile syscall may be used to deliver
# files.  This usually improves server performance, but must
# be turned off when serving from networked-mounted
# filesystems or if support for these functions is otherwise
# broken on your system.
# Defaults if commented: EnableMMAP On, EnableSendfile Off
#
#EnableMMAP off
EnableSendfile on

#バージョン非表示
ServerTokens ProductOnly
ServerSignature off

# Supplemental configuration
#
# Load config files in the "/etc/httpd/conf.d" directory, if any.
IncludeOptional conf.d/*.conf

EOF

        #SSLの設定変更
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


        # php7系のインストール
        echo "phpをインストールします"
        echo ""
        start_message
        yum -y install --enablerepo=remi,remi-php72 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql phpmyadmin
        echo "phpのバージョン確認"
        echo ""
        php -v
        echo ""
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
rユーザー
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

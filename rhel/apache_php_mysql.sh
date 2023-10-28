#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

注意点：conohaのポートは全て許可前提となります。もしくは80番、443番の許可をしておいてください。システムのfirewallはオン状態となります。userユーザーのパスワードはランダム生成となります。最後に表示されます

目的：システム更新+apache2.4系のインストール
・apache2.4.s
・mod_sslのインストール
・PHP8系のインストール
・MySQL8のインストール
・userの作成

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

#user8系か確認
if [ -e /etc/redhat-release ]; then
    DIST="redhat"
    DIST_VER=`cat /etc/redhat-release | sed -e "s/.*\s\([0-9]\)\..*/\1/"`
    #DIST_VER=`cat /etc/redhat-release | perl -pe 's/.*release ([0-9.]+) .*/$1/' | cut -d "." -f 1`

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "8" ] || [ $DIST_VER = "9" ];then

      #SELinuxの確認
SElinux=`which getenforce`
if [ "`${SElinux}`" = "Disabled" ]; then
  echo "SElinuxは無効なのでそのまま続けていきます"
else
  echo "SElinux有効のため、一時的に無効化します"
  setenforce 0

  getenforce
  #exit 1
fi

        #EPELリポジトリのインストール
        start_message
        dnf remove -y epel-release
        dnf -y install epel-release
        end_message

        #gitリポジトリのインストール
        start_message
        dnf -y install git
        end_message

        start_message
        if [ $DIST_VER = "8" ];then
        
        #remiリポジトリのインストール
        dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
        echo "PHP8.2を有効化"
        dnf module enable -y php:remi-8.2

        #PHPのインストール
        #8と9でリポジトリが違うのでそれぞれでわける

        echo "PHP8.2のインストール"
        dnf install -y php
        break #強制終了

        elif [ $DIST_VER = "9" ];then
        #Alma、Rockylinux9の時はこっちを実行
        echo "remiリポジトリのインストール"
        dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm
        
        echo "PHP8.2を有効化"
        dnf module enable -y php:remi-8.2

        echo "PHP8.2のインストール"
        dnf install -y php
        break #強制終了
        else
        echo "どれでもない"
        fi

        #必要な拡張モジュールをインストール
        echo "モジュールのインストール"
        dnf install -y php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip php-intl php-common php-bcmath php-imagick php-xmlrpc php-json php-readline php-memcached php-redis php-mbstring php-apcu php-xml php-dom php-redis php-memcached php-memcache
        end_message

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



        # dnf updateを実行
        echo "dnf updateを実行します"
        echo ""

        start_message
        #dnf -y update
        end_message

        # apacheのインストール
        echo "apacheをインストールします"
        dnf  install -y httpd mod_ssl



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

        


        #データベースの作成
        start_message
        echo "データベースをインストールします"
        #wget wget https://buildree.com/download/common/database/rdbm80.sh
        curl -L https://buildree.com/download/common/database/rdbm80.sh -o database.sh
        source ./database.sh
        
        #ユーザー作成
        start_message
        echo "ユーザーを作成します"
        USERNAME='unicorn'
        PASSWORD=$(more /dev/urandom  | tr -d -c '[:alnum:]' | fold -w 10 | head -1)

        useradd -m -G apache -s /bin/bash "${USERNAME}"
        echo "${PASSWORD}" | passwd --stdin "${USERNAME}"
        echo "パスワードは"${PASSWORD}"です。"
        #ファイルの保存
        start_message
        echo "パスワードなどを保存"
cat <<EOF >/root/user.txt
${USERNAME} = ${PASSWORD}
EOF


        #所属グループ表示
        echo "所属グループを表示します"
        getent group apache
        end_message

        #所有者の変更
        start_message
        echo "ドキュメントルートの所有者をunicorn、グループをapacheにします"
        chown -R "${USERNAME}":apache /var/www/html
        end_message

        # apacheの起動
        echo "apacheを起動します"
        start_message
        systemctl start httpd.service




        #自動起動の設定
        start_message
        systemctl enable httpd
        systemctl enable mysqld
        systemctl list-unit-files --type=service | grep httpd
        systemctl list-unit-files --type=service | grep mysqld
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
        http://IPアドレス or ドメイン名
        https://IPアドレス or ドメイン名
        で確認してみてください

        設定ファイルは
        /etc/httpd/conf.d/ドメイン名.conf
        となっています


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
        SSLのconfファイルに｢Protocols h2 http/1.1｣と追記してください
        https://www.logw.jp/server/8359.html

        例）
        <VirtualHost *:443>
            ServerName logw.jp
            ServerAlias www.logw.jp

            Protocols h2 http/1.1　←追加
            DocumentRoot /var/www/html


        <Directory /var/www/html/>
            AllowOverride All
            Require all granted
        </Directory>

        </VirtualHost>

        ドキュメントルートの所有者：user
        グループ：apache
        になっているため、ユーザー名とグループの変更が必要な場合は変更してください
EOF

        echo "userユーザーのパスワードは"${PASSWORD}"です。"
      else
        echo "RedHat系ではないため、このスクリプトは使えません。このスクリプトのインストール対象はRedHat8，9系です。"
      fi
    fi

else
  echo "このスクリプトのインストール対象はuser7です。user7以外は動きません。"
  cat <<EOF
  検証LinuxディストリビューションはDebian・Ubuntu・Fedora・Arch Linux（アーチ・リナックス）となります。
EOF
fi
exec $SHELL -l

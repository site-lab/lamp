# LAMP
CentOS7専用となります。**centos7 minimal インストール** した状態で何もはいっていない状態で必要なファイルを実行してください
LAMP環境を構築します
※自己責任で実行してください

## テスト環境
* conohaのVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### 実行方法
SFTPなどでアップロードをして、rootユーザーもしくはsudo権限で実行
wgetを使用する場合は[環境構築スクリプトを公開してます](https://www.logw.jp/cloudserver/8886.html)を閲覧してください。
wgetがない場合は **yum -y install wget** でインストールしてください

**sh ファイル名.sh** ←同じ階層にある場合

**sh /home/ユーザー名/ファイル名.sh** ユーザー階層にある場合（rootユーザー実行時）

## [apache_php72_mariadb103.sh](https://github.com/site-lab/lamp/blob/master/apache_php72_mariadb103.sh)
Apache2.4+PHP7.2+MariaDB10.3をインストールします。
自動起動もOnとなります
有効機能
* HTTP2
* firewallのポート許可(80番、443番)
* gzip圧縮の設定
* SSL
* スロークエリ有効化

となります。PHP7は **モジュール版** となります

## [apache_php72_fcgid_mariadb103.sh](https://github.com/site-lab/lamp/blob/master/apache_php72_fcgid_mariadb103.sh)
Apache2.4+PHP7.2+MariaDB10.3をインストールします。
自動起動もOnとなります
有効機能
* HTTP2
* firewallのポート許可(80番、443番)
* gzip圧縮の設定
* SSL
* スロークエリ有効化

となります。PHP7は **FastCGI版** となります。


## [apache_php72_mysql57.sh](https://github.com/site-lab/lamp/blob/master/apache_php72_mysql57.sh)
Apache2.4+PHP7.2+MariaDB5.7をインストールします。
自動起動もOnとなります
有効機能
* HTTP2
* firewallのポート許可(80番、443番)
* gzip圧縮の設定
* SSL
* スロークエリ有効化
* デフォルトパスワード有効期限無効

となります。PHP7は **モジュール版** となります

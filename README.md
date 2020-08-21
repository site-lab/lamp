# LAMP
CentOS7専用となります。**centos7 minimal インストール** した状態で何もはいっていない状態で必要なファイルを実行してください
LAMP環境を構築します。HTTP2対応バージョンもあります。
※自己責任で実行してください


## HTTP2の確認方法

インストール後、**# find / -name mod_http2.so** といれてください。**/usr/lib64/httpd/modules/mod_http2.so** とでてきたら、HTTP2に対応しているバージョンとなります。

## テスト環境
### conohaのVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### さくらののVPS
* メモリ：512MB
* CPU：1コア
* SSD：20GB

### さくらのクラウド
* メモリ：1GB
* CPU：1コア
* SSD：20GB

### IDCFクラウド
* メモリ：1GB
* CPU：1コア
* SSD：15GB

### 実行方法
SFTPなどでアップロードをして、rootユーザーもしくはsudo権限で実行
wgetを使用する場合は[Buildree](https://buildree.com/)を閲覧してください。
wgetがない場合は **yum -y install wget** でインストールしてください

**sh ファイル名.sh** ←同じ階層にある場合

**sh /home/ユーザー名/ファイル名.sh** ユーザー階層にある場合（rootユーザー実行時）

## 共通内容
* epelインストール
* gitのインストール
* システム更新
* mod_sslのインストール
* firewallのポート許可(80番、443番)
* gzip圧縮の設定
* centosユーザーの作成
* スロークエリ有効化

## [apache_php_mariadb.sh](https://github.com/site-lab/lamp/blob/master/apache_php_mariadb.sh)
Apache2.4系+PHP7.x+MariaDB10系をインストールします。

PHPのバージョンは7.3～7.4まで選択となります
PHP7は **モジュール版** となります

Apache、PHP、MariaDBを選択してインストールします

## [apache_php_mysql.sh](https://github.com/site-lab/lamp/blob/master/apache_php_mysql.sh)
Apache2.4系+PHP7.x+MySQLをインストールします。

PHPのバージョンは7.3～7.4まで選択となります。
Apache、PHP、MariaDBを選択してインストールします
有効機能
* デフォルトパスワード有効期限無効
* PHP7は **モジュール版** となります

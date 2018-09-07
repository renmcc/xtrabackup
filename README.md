#描述：
    用于mysql数据库增量备份还原

脚本逻辑：
    备份数据库中所有innodb的所有库,原因是不都备份还原时无法覆盖ibdata1
    按天备份，第一次执行完全备份,之后检查备份目录下是否有日期目录(20180724)并且目录里是否有backup_type是full-backuped的备份，没有仍然做完全备份，有则基于上次备份做增量备份。
    还原时，选择两个列表，第一个是日期列表（需要还原哪天的备份），第二选择还原当天哪一个备份

备份目录结构：
[root@localhost sql_bak]# ll 20180724/
total 56
drwxr-xr-x. 4 root root 4096 Jul 24 16:01 20180724160103        #备份目录
-rw-r--r--. 1 root root 4262 Jul 24 16:01 20180724160103.log    #对应的备份日志
drwxr-x---. 4 root root 4096 Jul 24 16:01 20180724160139
-rw-r--r--. 1 root root 4379 Jul 24 16:01 20180724160139.log
drwxr-x---. 4 root root 4096 Jul 24 16:06 20180724160653
-rw-r--r--. 1 root root 4379 Jul 24 16:06 20180724160653.log
drwxr-x---. 4 root root 4096 Jul 24 16:07 20180724160754
-rw-r--r--. 1 root root 4380 Jul 24 16:07 20180724160754.log
-rw-r--r--. 1 root root  538 Jul 24 16:01 my.cnf                #备份配置文件(完全备份时备份一次)
-rw-r--r--. 1 root root   60 Jul 24 16:07 order                 #基准文件,保存备份目录的顺序,用于增量和还原时校对目录


还原临时目录：
因为备份一旦执行还原就无法再被基于进行增量备份，所以还原时移动到临时目录
[root@localhost tmp]# ll /tmp/xbackup_restore/
total 20
drwxr-xr-x. 4 root root 4096 Jul 24 16:08 20180724160103        #备份目录
drwxr-x---. 4 root root 4096 Jul 24 16:08 20180724160139
drwxr-x---. 4 root root 4096 Jul 24 16:08 20180724160653
drwxr-x---. 4 root root 4096 Jul 24 16:08 20180724160754
-rw-r--r--. 1 root root   60 Jul 24 16:08 order                 #基准文件

用法：
修改脚本开头的变量
    BACKUPDIR=/data0/sql_bak                                    #备份目录
    DATADIR=/data0/mysql/data                                   #数据库目录
    DBCONF=/etc/my.cnf                                          #配置文件
    DBUSER=root
    DBPASSWD='123456'

    备份
    sh xtrabackup.sh backup
    还原
    1、关闭mysql数据库
    2、执行还原脚本
        sh xtrabackup.sh restore
    3、开启mysql数据库，检查数据

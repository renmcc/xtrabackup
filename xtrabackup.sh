#!/bin/bash

TIMESTAMP=`date +%Y%m%d`
TIMESTAMP1=`date +%Y%m%d%H%M%S`
#备份目录
BACKUPDIR=/data0/sql_bak
#数据库目录
DATADIR=/data0/mysql/data
#配置文件目录
DBCONF=/etc/my.cnf
DBUSER=root
DBPASSWD='910202'

function Initialization() {
    which xtrabackup &> /dev/null && { echo "Xtrabackup has been installed" ; return ; }
echo -n '[percona]
name = CentOS $releasever - Percona
baseurl=http://repo.percona.com/centos/$releasever/os/$basearch/
enabled = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-percona
gpgcheck = 1' > /etc/yum.repos.d/Percona.repo

cat << EOF > /etc/pki/rpm-gpg/RPM-GPG-KEY-percona
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.9 (GNU/Linux)

mQGiBEsm3aERBACyB1E9ixebIMRGtmD45c6c/wi2IVIa6O3G1f6cyHH4ump6ejOi
AX63hhEs4MUCGO7KnON1hpjuNN7MQZtGTJC0iX97X2Mk+IwB1KmBYN9sS/OqhA5C
itj2RAkug4PFHR9dy21v0flj66KjBS3GpuOadpcrZ/k0g7Zi6t7kDWV0hwCgxCa2
f/ESC2MN3q3j9hfMTBhhDCsD/3+iOxtDAUlPMIH50MdK5yqagdj8V/sxaHJ5u/zw
YQunRlhB9f9QUFfhfnjRn8wjeYasMARDctCde5nbx3Pc+nRIXoB4D1Z1ZxRzR/lb
7S4i8KRr9xhommFnDv/egkx+7X1aFp1f2wN2DQ4ecGF4EAAVHwFz8H4eQgsbLsa6
7DV3BACj1cBwCf8tckWsvFtQfCP4CiBB50Ku49MU2Nfwq7durfIiePF4IIYRDZgg
kHKSfP3oUZBGJx00BujtTobERraaV7lIRIwETZao76MqGt9K1uIqw4NT/jAbi9ce
rFaOmAkaujbcB11HYIyjtkAGq9mXxaVqCC3RPWGr+fqAx/akBLQ2UGVyY29uYSBN
eVNRTCBEZXZlbG9wbWVudCBUZWFtIDxteXNxbC1kZXZAcGVyY29uYS5jb20+iGAE
ExECACAFAksm3aECGwMGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRAcTL3NzS79
Kpk/AKCQKSEgwX9r8jR+6tAnCVpzyUFOQwCfX+fw3OAoYeFZB3eu2oT8OBTiVYu5
Ag0ESybdoRAIAKKUV8rbqlB8qwZdWlmrwQqg3o7OpoAJ53/QOIySDmqy5TmNEPLm
lHkwGqEqfbFYoTbOCEEJi2yFLg9UJCSBM/sfPaqb2jGP7fc0nZBgUBnFuA9USX72
O0PzVAF7rCnWaIz76iY+AMI6xKeRy91TxYo/yenF1nRSJ+rExwlPcHgI685GNuFG
chAExMTgbnoPx1ka1Vqbe6iza+FnJq3f4p9luGbZdSParGdlKhGqvVUJ3FLeLTqt
caOn5cN2ZsdakE07GzdSktVtdYPT5BNMKgOAxhXKy11IPLj2Z5C33iVYSXjpTelJ
b2qHvcg9XDMhmYJyE3O4AWFh2no3Jf4ypIcABA0IAJO8ms9ov6bFqFTqA0UW2gWQ
cKFN4Q6NPV6IW0rV61ONLUc0VFXvYDtwsRbUmUYkB/L/R9fHj4lRUDbGEQrLCoE+
/HyYvr2rxP94PT6Bkjk/aiCCPAKZRj5CFUKRpShfDIiow9qxtqv7yVd514Qqmjb4
eEihtcjltGAoS54+6C3lbjrHUQhLwPGqlAh8uZKzfSZq0C06kTxiEqsG6VDDYWy6
L7qaMwOqWdQtdekKiCk8w/FoovsMYED2qlWEt0i52G+0CjoRFx2zNsN3v4dWiIhk
ZSL00Mx+g3NA7pQ1Yo5Vhok034mP8L2fBLhhWaK3LG63jYvd0HLkUFhNG+xjkpeI
SQQYEQIACQUCSybdoQIbDAAKCRAcTL3NzS79KlacAJ0aAkBQapIaHNvmAhtVjLPN
wke4ZgCePe3sPPF49lBal7QaYPdjqapa1SQ=
=qcCk
-----END PGP PUBLIC KEY BLOCK-----
EOF

yum -y install percona-xtrabackup-24
}

#用于收集库中引擎为innodb的库名
function Check_innodb() {
    local MYSQLBIN=$1
    local VALUE=1
    local ALL_DB=`${MYSQLBIN} -e "show databases"|egrep -v '^Database$|^information_schema$|^performance_schema$|^mysql$|^test$'`
    for DB in ${ALL_DB}; do
        local subtable=`${MYSQLBIN} ${DB} -e "show tables"|tail -n1`
        local ENGINE=`${MYSQLBIN} ${DB} -e "show create table ${subtable}"|awk -F'=' '/ENGINE=/{print $2}'|awk '{print $1}'`
        if [ "${ENGINE}" == "InnoDB" ]; then
            DBS_ARRAY[${VALUE}]=${DB}
            ((VALUE++))
        fi
    done
    echo "${DBS_ARRAY[@]}"
}

function All_db() {
    if [ -x "/usr/local/mysql/bin/mysql" ]; then
        Check_innodb "/usr/local/mysql/bin/mysql ${MYSQLBIN} -u${DBUSER} -p${DBPASSWD} -h127.0.0.1"
    else
        Check_innodb "mysql ${MYSQLBIN} -u${DBUSER} -p${DBPASSWD} -h127.0.0.1"
    fi
}

#完全备份
function Full_backup() {
    [ -d "${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1}" ] || mkdir -p ${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1}
    local LOGS=${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1}.log
    echo ${TIMESTAMP1} > ${BACKUPDIR}/${TIMESTAMP}/order
    DATABASES=`All_db`
    [ -z "$DATABASES" ] && { echo 'DATABASES is null' > $LOGS; exit; }
    cp ${DBCONF} ${BACKUPDIR}/${TIMESTAMP}/my.cnf
    innobackupex --defaults-file=${DBCONF} --user=${DBUSER} --host=127.0.0.1 --port=3306 --password=${DBPASSWD} --databases="${DATABASES}" --no-timestamp ${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1} 2> ${LOGS} 
    tail -n1 ${LOGS}|grep -q 'completed OK!' || { echo "backup databases failed." >> ${LOGS} ; exit 22 ; }
}

#增量备份
function Incremental_backup() {
    local FULLBACKUP=$1
    local LOGS=${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1}.log
    echo ${TIMESTAMP1} >> ${BACKUPDIR}/${TIMESTAMP}/order
    DATABASES="`All_db`" 
    [ -z "$DATABASES" ] && { echo 'DATABASES is null' > $LOGS; exit; }
    innobackupex --defaults-file=${DBCONF} --incremental --user=${DBUSER} --host=127.0.0.1 --port=3306 --password=${DBPASSWD} --databases="${DATABASES}" --no-timestamp --incremental-basedir=${FULLBACKUP} ${BACKUPDIR}/${TIMESTAMP}/${TIMESTAMP1} 2> ${LOGS} 
    tail -n1 ${LOGS}|grep -q 'completed OK!'  || { echo "backup databases failed." >> ${LOGS} ; exit 32 ; }
}

#备份主函数
function BackupDB() {
    rpm -q "percona-xtrabackup-24" > /dev/null || { echo "xtrabackup-24 not found"; exit 10 ; } 
    [ ! -d  "${BACKUPDIR}/${TIMESTAMP}" ] && { Full_backup; return; }
    for i in `find ${BACKUPDIR}/${TIMESTAMP}/ -maxdepth 1 -type d|sed '1d'`; do
        [ ! -f "${i}/xtrabackup_checkpoints" ] && continue
        BACKUPTYPE=`awk -F '[= ]+' '/^backup_type/{print $2}' ${i}/xtrabackup_checkpoints`
        if [ "${BACKUPTYPE}" == "full-backuped" ]; then
            incremental_basedir=${BACKUPDIR}/${TIMESTAMP}/`tail -n1 ${BACKUPDIR}/${TIMESTAMP}/order`  
            Incremental_backup "${incremental_basedir}"
            return
        fi
    done
    Full_backup
}

#还原列表函数
function choise_list(){
    index=1
    state=0
    back_path=$1
    array=()
    [ -d "${back_path}" ] || { echo "No backup file!!" ; exit 30 ; }
    for i in `find ${back_path}/ -maxdepth 1 -type d|sed '1d'`; do
        array[$index]=$i    
        let index+=1
    done
    echo -e "Select a point in time to restore"
    for i in `seq ${#array[*]}`; do
        echo -e "\t$i) ${array[$i]}"
    done    
    read  -p "Select restore date:" SELECT
    for i in `seq ${#array[*]}`; do
        if [ "$SELECT" -eq "$i" ]; then
            return $SELECT
        fi
    done
    [ $state -eq 0 ] && { echo 'Choice of errors'; exit; }
}

#还原主函数
function RestoreDB() {
    rpm -q "percona-xtrabackup-24" > /dev/null || { echo "xtrabackup-24 not found"; exit 10 ; } 
    #选择恢复日期列表
    choise_list ${BACKUPDIR}
    restore_path=${array[$?]}
    echo $restore_path
    #选择当天需要还原文件目录列表
    choise_list ${restore_path}
    restore_path1=${array[$?]}
    #创建恢复临时目录
    tmpdir=/tmp/xbackup_restore
    [ -d "${tmpdir}" ] && rm -rf ${tmpdir}/* || mkdir -p ${tmpdir}
    #$restore_path1在order文件中的行号
    restore_dir=`echo $restore_path1|awk -F'/' '{print $NF}'`
    line_num=`sed -n "/${restore_dir}/=" ${restore_path}/order`
    #复制备份目录到临时恢复目录
    head -n $line_num ${restore_path}/order > $tmpdir/order
    for i in `cat $tmpdir/order`; do
        cp -r $restore_path/$i $tmpdir
    done
    #开始恢复
    full_back_path=`head -n1 ${tmpdir}/order`
    full_back_path=$tmpdir/$full_back_path
    innobackupex --apply-log --redo-only $full_back_path
    #恢复增量到全备上面
    inc_back_path=`cat $tmpdir/order |tail -n +2`
    if [ ! -z "$inc_back_path" ]; then
        for i in $inc_back_path; do
            innobackupex --apply-log --redo-only $full_back_path --incremental-dir=${tmpdir}/$i
        done
    fi
    #最后执行事务
    innobackupex --apply-log $full_back_path
    #关闭mysql服务
    ps -ef |grep -v grep|grep -q mysqld && /etc/init.d/mysqld stop
    #备份原数据，然后恢复
    cp -r ${DATADIR} ${DATADIR}.${TIMESTAMP1}
    rm -f $DATADIR/{ibdata1,ib_logfile*}
    cp -r $full_back_path/{ibdata1,ib_logfile*} ${DATADIR}/
    DBS=`find $full_back_path -maxdepth 1 -type d|sed '1d'`
    for i in $DBS; do
        rm -rf $DATADIR/`echo $i|awk -F'/' '{print $NF}'`
        cp -r $i $DATADIR/
    done
    chown -R mysql.mysql ${DATADIR}
    #恢复配置文件
    cp $restore_path/my.cnf $DBCONF     
}

function Main() {
    local USAGE="Usage:$(basename $0) [install|backup|restore]"
    case "${1}" in
        install)
            Initialization
            ;;
        backup)
            BackupDB
            ;;
        restore)
            RestoreDB 
            ;;
        *)
            echo ${USAGE}
            exit 5 
            ;;
    esac
}
Main $@

#!/bin/bash
################
# Scripts name : check-process.sh
# Usage        : ./check-process.sh
#                同一ディレクトリにcheck-process.confを配置し、cronで定期実行する。
# Description  : Linuxプロセスチェックスクリプト
# Create       : 2017/12/14 tech-mmmm (https://tech-mmmm.blogspot.com/)
# Modify       : 
################

currentdir=`dirname $0`
conffile="${currentdir}/check-process.conf"    # 設定ファイル
tmpfile="${currentdir}/check-process.tmp"      # プロセス情報保存用一時ファイル
rc=0    # Retuan Code確認用

# すでにDownしているプロセス情報を取得
if [ -f ${tmpfile} ]; then
    down_process=`paste -d "|" -s ${tmpfile}`
fi
echo -n > ${tmpfile}

# 設定ファイル読み込み
cat ${conffile} | while read line
do
    # 空白区切りで分割
    set -- ${line}
    [ $rc -lt $? ] && rc=$?
    
    # コメント行と空行を処理しない
    if [ `echo $1 | grep -v -e '^ *#' -e '^$' | wc -c` -gt 0 ]; then
        [ $rc -lt $? ] && rc=$?
        
        # 現在のプロセス数を取得
        count=`ps ahxo args | grep $1 | grep -v -e "^grep" | wc -l`
        [ $rc -lt $? ] && rc=$?
        
        # プロセス数チェック
        if [ ${count} -lt $2 ]; then
            # Down時の処理
            # すでにDownしているプロセスか確認
            if [ -n "${down_process}" ] && [ `echo $1 | egrep "${down_process}" | wc -c` -gt 0 ]; then
                # すでにDown
                [ $rc -lt $? ] && rc=$?
                message="[INFO] Process \"$1\" still down"
            else
                # 初回Down
                [ $rc -lt $? ] && rc=$?                
                message="[ERROR] Process \"$1\" down"
            fi
            # ログへ出力
            logger $message
            [ $rc -lt $? ] && rc=$?
            
            # Donwしているプロセス情報を出力
            echo $1 >> ${tmpfile}
        else
            # Up時の処理
            # Downしていたプロセスか確認
            if [ -n "${down_process}" ] && [ `echo $1 | egrep "${down_process}" | wc -c` -gt 0 ]; then
                # Downだった
                [ $rc -lt $? ] && rc=$?
                message="[INFO] Process \"$1\" up"
                
                # ログへ出力
                logger $message
                [ $rc -lt $? ] && rc=$?
            fi
        fi
    fi
done

# エラー処理
if [ $rc -gt 0 ]; then
    logger "[ERROR] Process check script error (Max Return Code : ${rc})"
fi

exit $?

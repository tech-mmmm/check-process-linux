#!/bin/bash
################
# Scripts name : check-process.sh
# Usage        : ./check-process.sh
#                同一ディレクトリにcheck-process.confを配置し、cronで定期実行する。
# Description  : Linuxプロセスチェックスクリプト
# Create       : 2017/12/14 tech-mmmm (https://tech-mmmm.blogspot.com/)
# Modify       : 2022/05/01 tech-mmmm (https://tech-mmmm.blogspot.com/)
################

currentdir="$(dirname "$0")"
conffile="${currentdir}/check-process.conf"    # 設定ファイル
tmpfile="${currentdir}/check-process.tmp"      # プロセス情報保存用一時ファイル

# すでにDownしているプロセス情報を取得
if [ -f "${tmpfile}" ]; then
    down_process=$(paste -d "|" -s "${tmpfile}")
fi
echo -n > "${tmpfile}"

# 設定ファイル読み込み
while read line || [ -n "${line}" ]; do
    # 空白区切りで分割
    process_name=$(echo "${line}" | awk '{print $1}')
    process_num=$(echo "${line}" | awk '{print $2}')
    
    # コメント行と空行を処理しない
    if [ "$(echo "${process_name}" | grep -c -v -e '^ *#' -e '^$')" -gt 0 ]; then      
        # 現在のプロセス数を取得
        count=$(ps ahxo args | grep "${process_name}" | grep -c -v -e "^grep")
        
        # プロセス数チェック
        if [ "${count}" -lt "${process_num}" ]; then
            # Down時の処理
            # すでにDownしているプロセスか確認
            if [ -n "${down_process}" ] && [ "$(echo ${process_name} | grep -c -E ${down_process})" -gt 0 ]; then
                # すでにDown
                message="[INFO] Process \"${process_name}\" still down"
            else
                # 初回Down
                message="[ERROR] Process \"${process_name}\" down"
            fi
            # ログへ出力
            echo "${message}"
            logger "${message}"
            
            # Donwしているプロセス情報を出力
            echo "${process_name}" >> "${tmpfile}"
        else
            # Up時の処理
            # Downしていたプロセスか確認
            if [ -n "${down_process}" ] && [ "$(echo ${process_name} | grep -c -E ${down_process})" -gt 0 ]; then
                # Downだった
                message="[INFO] Process \"${process_name}\" up"
            else
                # すでにUp
                message="[INFO] Process \"${process_name}\" still up"
            fi
            # ログへ出力
            echo "${message}"
            logger "${message}"
        fi
    fi
done < "${conffile}"

exit 0

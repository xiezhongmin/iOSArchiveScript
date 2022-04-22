#!/bin/bash
#使用方法

if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

# -------------------------------- 需要配置的参数 --------------------------------

#工程名 将XXX替换成自己的工程名
project_name=XXX

#scheme名 将XXX替换成自己的sheme名
scheme_name=XXX

#填写工程的 bundle Id
bundle_id=XXX

#填写企业微信机器人的URL
WEBHOOK_URL=""

#填写 fir api_token
api_token=XXX

#填写构建触发者名字
BUILD_TRIGGER=""

#填写需要指定@人的手机号码
notify_iphone=13800000000

#需要打包上传App Store填写:
#苹果证书的AppleID
AppleID=XXX

#苹果证书的密码
AppleID_PWD=XXX

# -------------------------------- end --------------------------------


#工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#打包模式 Debug/Release
development_mode=Debug

#build文件夹路径
build_path=${project_path}/build

#plist文件所在路径
exportOptionsPlistPath=${project_path}/exportDebugTest.plist

#导出.ipa文件所在路径
exportIpaPath=${project_path}/IPADir/${development_mode}

#打包二维码地址
qrcode_path=${project_path}/IPADir/${development_mode}/fir-$project_name.png

#Fir APP INFO URL
APP_INFO_URL="http://api.bq04.com/apps/latest/$bundle_id?api_token=$api_token&bundle_id=$bundle_id"

#当前环境
ENV="测试环境"


echo "请输入打包模式? [0:debug 1:ad-hoc 2:app-store] 默认debug"
read number
if ([[ $number != 1 ]] && [[ $number != 2 ]] && [[ $number != 0 ]]); then
number=0
fi

echo "请输入拉取git提交记录前多少条？默认3条"
read count
if ([[ !$count ]]); then
count=3
fi

echo "清理垃圾文件 \n"
rm -rf build/
rm -rf IPADir/Debug/

if [ $number == 0 ]; then
development_mode=Debug
exportOptionsPlistPath=${project_path}/exportDebugTest.plist
ENV="测试环境"
echo "正在准备打----------------------Debug包---------------------------"
else if [ $number == 1 ]; then
development_mode=Release
exportOptionsPlistPath=${project_path}/exportHocTest.plist
ENV="线上环境"
echo "正在准备打----------------------Hoc包---------------------------"
else
development_mode=Release
exportOptionsPlistPath=${project_path}/exportAppstore.plist
ENV="线上环境"
echo "正在准备打----------------------Appstore包---------------------------"
fi

fi

echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit


echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive
#-quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

echo "清理打包垃圾build"
rm -rf build/

echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'

if [ $number == 3 ];then

#验证并上传到App Store
# -u 后面是AppleID的账号，-p后面是苹果证书密码密码
altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
"$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u $AppleID -p $AppleID_PWD -t ios --output-format xml
"$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  $AppleID -p $AppleID_PWD -t ios --output-format xml
else

#上传到Fir
fir login -T $api_token
fir publish $exportIpaPath/$scheme_name.ipa


# 通知企业微信
MD5_STR=`md5 -r $qrcode_path`
DATA=`base64 $qrcode_path`
MD5=${MD5_STR: 0: 32}
TIME=$(date "+%Y/%m/%d-%H:%M:%S")

#获取APP信息
result=$(curl --location --request GET ${APP_INFO_URL} \
--header 'Content-Type: application/json')

app_name=`echo $result | jq -r '.name'`
app_version=`echo $result | jq -r '.versionShort'`
app_build=`echo $result | jq -r '.build'`

#获取git提交记录
commit_list=$(git log --pretty=format:\"%an-%h-%s-%H\" -$count)

commit_list=`echo $commit_list | sed 's/\"//g'`

commit_list=`echo $commit_list | sed 's/[A-Za-z:/-_.-]//g'`

for i in $commit_list; do commit="$commit$i\n"; done

commit=`echo $commit | sed $'s/\'//g'`

for i in $commit; do commit_log="$commit_log$i\n"; done


#发送到企业微信
curl --location --request POST ${WEBHOOK_URL} \
--header 'Content-Type: application/json' \
-d '{"msgtype": "text","text": {"content": "本次构建由：'$BUILD_TRIGGER'触发\n构建时间：'$TIME'\n项目名称：iOS '$app_name'\n当前环境：'$ENV'\nApp版本号：'$app_version'\nbuild号：'$app_build'\nBUG修复(自动拉取git提交记录)如下：\n'$commit_log'二维码如下：", "mentioned_mobile_list":["'$notify_iphone'","@all"]}}'

curl --location --request POST ${WEBHOOK_URL} \
--header 'Content-Type: application/json' \
-d '{"msgtype": "image","image": {"base64":"'$DATA'", "md5":"'$MD5'"}}'

echo '/// 已打包上传完成 '

fi

exit 0


